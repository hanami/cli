# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Create, :app_integration do
  subject(:command) {
    described_class.new(
      system_call: system_call,
      test_env_executor: test_env_executor,
      out: out
    )
  }

  let(:system_call) { Hanami::CLI::SystemCall.new }
  let(:test_env_executor) { instance_spy(Hanami::CLI::InteractiveSystemCall) }

  let(:out) { StringIO.new }
  def output = out.string

  before do
    # Prevent the command from exiting the spec run in the case of unexpected system call failures
    allow(command).to receive(:exit)
  end

  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  before do
    with_directory(@dir = make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      require "hanami/setup"
      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end

    # Execute the test inside the context of the created app. This is a requirement for SQLite
    # databases to work properly in CI.
    Dir.chdir(@dir)
  end

  context "single db in app" do
    def before_prepare
      write "config/db/.keep", ""
      write "app/relations/.keep", ""
    end

    describe "sqlite" do
      before do
        ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
      end

      it "creates the database" do
        command.call

        expect(Hanami.app.root.join("db", "app.sqlite3").exist?).to be true

        expect { Hanami.app["db.gateway"] }.not_to raise_error

        expect(output).to include "database db/app.sqlite3 created"
      end

      it "does not create the database if it already exists" do
        FileUtils.mkdir(@dir.join("db"))
        FileUtils.touch(@dir.join("db", "app.sqlite3"))

        command.call

        expect(output).to include "database db/app.sqlite3 created"
      end
    end

    describe "postgres", :postgres do
      before do
        ENV["DATABASE_URL"] = "#{POSTGRES_BASE_URL}_app"
      end

      it "creates the database" do
        command.call

        expect { Hanami.app["db.gateway"] }.not_to raise_error

        expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_app created"
      end

      it "does not create the database if it alredy exists" do
        command.run_command(Hanami::CLI::Commands::App::DB::Create)
        out.truncate(0)

        command.call

        expect { Hanami.app["db.gateway"] }.not_to raise_error

        expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_app created"
      end
    end

    describe "mysql", :mysql do
      before do
        ENV["DATABASE_URL"] = "#{MYSQL_BASE_URL}_app"
      end

      it "creates the database" do
        command.call

        expect { Hanami.app["db.gateway"] }.not_to raise_error

        expect(output).to include "database #{MYSQL_BASE_DB_NAME}_app created"
      end

      it "does not create the database if it already exists" do
        command.run_command(Hanami::CLI::Commands::App::DB::Create)
        out.truncate(0)

        command.call

        expect { Hanami.app["db.gateway"] }.not_to raise_error

        expect(output).to include "database #{MYSQL_BASE_DB_NAME}_app created"
      end
    end
  end

  context "multiple dbs across app and slices" do
    def before_prepare
      write "config/db/.keep", ""
      write "app/relations/.keep", ""
      write "slices/main/config/db/.keep", ""
      write "slices/main/relations/.keep", ""
    end

    describe "sqlite" do
      before do
        ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
        ENV["MAIN__DATABASE_URL"] = "sqlite://db/main.sqlite3"
      end

      it "creates each database" do
        command.call

        expect(Hanami.app.root.join("db", "app.sqlite3").exist?).to be true
        expect(Hanami.app.root.join("db", "main.sqlite3").exist?).to be true

        expect { Hanami.app["db.gateway"] }.not_to raise_error
        expect { Main::Slice["db.gateway"] }.not_to raise_error

        expect(output).to include "database db/app.sqlite3 created"
        expect(output).to include "database db/main.sqlite3 created"
      end

      it "creates the app database when given --app" do
        command.call(app: true)

        expect(Hanami.app.root.join("db", "app.sqlite3").exist?).to be true
        expect(Hanami.app.root.join("db", "main.sqlite3").exist?).to be false

        expect { Hanami.app["db.gateway"] }.not_to raise_error

        expect(output).to include "database db/app.sqlite3 created"
        expect(output).not_to include "db/main.sqlite3"
      end

      it "creates a slice database when given --slice" do
        command.call(slice: "main")

        expect(Hanami.app.root.join("db", "main.sqlite3").exist?).to be true
        expect(Hanami.app.root.join("db", "app.sqlite3").exist?).to be false

        expect { Main::Slice["db.gateway"] }.not_to raise_error

        expect(output).to include "database db/main.sqlite3 created"
        expect(output).not_to include "db/app.sqlite3"
      end

      it "prints errors for any create commands that fail and exits with non-zero status" do
        allow(system_call).to receive(:call).and_call_original
        allow(system_call)
          .to receive(:call)
          .with(a_string_matching(/sqlite3.+app.sqlite3/))
          .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 2, out: "", err: "app-db-err")

        command.call

        expect { Main::Slice["db.gateway"] }.not_to raise_error

        expect(Hanami.app.root.join("db", "app.sqlite3").exist?).to be false
        expect(Hanami.app.root.join("db", "main.sqlite3").exist?).to be true

        expect(output).to include "failed to create database db/app.sqlite3"
        expect(output).to include "app-db-err"

        expect(output).to include "database db/main.sqlite3 created"

        expect(command).to have_received(:exit).with(2).once
      end

      context "app with gateways" do
        def before_prepare
          write "config/db/.keep", ""
          ENV["DATABASE_URL__EXTRA"] = "sqlite://db/app_extra.sqlite3"
        end

        it "creates the databases for all the app's gateways when given --app" do
          expect { command.call(app: true) }
            .to change { Hanami.app.root.join("db", "app.sqlite3").exist? }.to(true)
            .and change { Hanami.app.root.join("db", "app_extra.sqlite3").exist? }.to(true)

          expect(output).to include_in_order(
            "database db/app.sqlite3 created",
            "database db/app_extra.sqlite3 created",
          )
        end

        it "creates the database for an app's gateway when given --app and --gateway" do
          expect { command.call(app: true, gateway: "extra") }
            .to change { Hanami.app.root.join("db", "app_extra.sqlite3").exist? }.to(true)
            .and not_change { Hanami.app.root.join("db", "app.sqlite3").exist? }.from(false)

          expect(output).to include "database db/app_extra.sqlite3 created"
          expect(output).not_to include "database/app.sqlite3"
        end
      end

      context "slice with gateways" do
        def before_prepare
          write "slices/main/config/db/.keep", ""
          ENV["MAIN__DATABASE_URL__EXTRA"] = "sqlite://db/main_extra.sqlite3"
        end

        it "creates the databases for all the slices's gateways when given --slice" do
          expect { command.call(slice: "main") }
            .to change { Hanami.app.root.join("db", "main.sqlite3").exist? }.to(true)
            .and change { Hanami.app.root.join("db", "main_extra.sqlite3").exist? }.to(true)

          expect(output).to include_in_order(
            "database db/main.sqlite3 created",
            "database db/main_extra.sqlite3 created",
          )
        end

        it "creates the database for an app's gateway when given --app and --gateway" do
          expect { command.call(slice: "main", gateway: "extra") }
            .to change { Hanami.app.root.join("db", "main_extra.sqlite3").exist? }.to(true)
            .and not_change { Hanami.app.root.join("db", "main.sqlite3").exist? }.from(false)

          expect(output).to include "database db/main_extra.sqlite3 created"
          expect(output).not_to include "database/main.sqlite3"
        end
      end
    end

    describe "postgres", :postgres do
      before do
        ENV["DATABASE_URL"] = "#{POSTGRES_BASE_URL}_app"
        ENV["MAIN__DATABASE_URL"] = "#{POSTGRES_BASE_URL}_main"
      end

      it "creates each database" do
        command.call

        expect { Hanami.app["db.gateway"] }.not_to raise_error
        expect { Main::Slice["db.gateway"] }.not_to raise_error

        expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_app created"
        expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_main created"
      end

      it "prints errors for any create commands that fail and exits with non-zero status" do
        allow(system_call).to receive(:call).and_call_original
        allow(system_call)
          .to receive(:call)
          .with(a_string_matching(/createdb.+_app/), anything)
          .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 2, out: "", err: "app-db-err")

        command.call

        expect { Hanami.app["db.gateway"] }.to raise_error Sequel::DatabaseConnectionError
        expect { Main::Slice["db.gateway"] }.not_to raise_error

        expect(output).to include "failed to create database #{POSTGRES_BASE_DB_NAME}_app"
        expect(output).to include "app-db-err"

        expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_main created"

        expect(command).to have_received(:exit).with(2).once
      end
    end

    describe "automatic test env execution" do
      before do
        ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
      end

      around do |example|
        as_hanami_cli_with_args(%w[db create]) { example.run }
      end

      it "re-executes the command in test env when run with development env" do
        command.call(env: "development")

        expect(test_env_executor).to have_received(:call).with(
          "bundle exec hanami",
          "db", "create",
          {
            env: hash_including("HANAMI_ENV" => "test")
          }
        )
      end

      it "does not re-execute the command when run with other environments" do
        command.call(env: "test")
        expect(test_env_executor).not_to have_received(:call)

        command.call(env: "production")
        expect(test_env_executor).not_to have_received(:call)
      end
    end
  end
end
