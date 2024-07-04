# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Create, :app_integration do
  subject(:command) { described_class.new(system_call: system_call, out: out) }

  let(:system_call) { Hanami::CLI::SystemCall.new }

  let(:out) { StringIO.new }
  def output; out.string; end

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
        ENV["DATABASE_URL"] = "sqlite://db/bookshelf_development.sqlite3"
      end

      it "creates the database" do
        command.call

        expect(Hanami.app.root.join("db", "bookshelf_development.sqlite3").exist?).to be true

        expect { Hanami.app["db.gateway"] }.not_to raise_error

        expect(output).to include "database db/bookshelf_development.sqlite3 created"
      end

      it "does not create the database if it already exists" do
        FileUtils.mkdir(@dir.join("db"))
        FileUtils.touch(@dir.join("db", "bookshelf_development.sqlite3"))

        command.call

        expect(output).to include "database db/bookshelf_development.sqlite3 created"
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
        ENV["DATABASE_URL"] = "sqlite://db/bookshelf_development.sqlite3"
        ENV["MAIN__DATABASE_URL"] = "sqlite://db/bookshelf_main_development.sqlite3"
      end

      it "creates each database" do
        command.call

        expect(Hanami.app.root.join("db", "bookshelf_development.sqlite3").exist?).to be true
        expect(Hanami.app.root.join("db", "bookshelf_main_development.sqlite3").exist?).to be true

        expect { Hanami.app["db.gateway"] }.not_to raise_error
        expect { Main::Slice["db.gateway"] }.not_to raise_error

        expect(output).to include "database db/bookshelf_development.sqlite3 created"
        expect(output).to include "database db/bookshelf_main_development.sqlite3 created"
      end

      it "creates the app database when given --app" do
        command.call(app: true)

        expect(Hanami.app.root.join("db", "bookshelf_development.sqlite3").exist?).to be true
        expect(Hanami.app.root.join("db", "bookshelf_main_development.sqlite3").exist?).to be false

        expect { Hanami.app["db.gateway"] }.not_to raise_error

        expect(output).to include "database db/bookshelf_development.sqlite3 created"
        expect(output).not_to include "db/bookshelf_main_development.sqlite3"
      end

      it "creates a slice database when given --slice" do
        command.call(slice: "main")

        expect(Hanami.app.root.join("db", "bookshelf_main_development.sqlite3").exist?).to be true
        expect(Hanami.app.root.join("db", "bookshelf_development.sqlite3").exist?).to be false

        expect { Main::Slice["db.gateway"] }.not_to raise_error

        expect(output).to include "database db/bookshelf_main_development.sqlite3 created"
        expect(output).not_to include "db/bookshelf_development.sqlite3"
      end

      it "prints errors for any create commands that fail and exits with non-zero status" do
        allow(system_call).to receive(:call).and_call_original
        allow(system_call)
          .to receive(:call)
          .with(a_string_matching(/sqlite3.+bookshelf_development.sqlite3/))
          .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 2, out: "", err: "app-db-err")

        command.call

        expect { Main::Slice["db.gateway"] }.not_to raise_error

        expect(Hanami.app.root.join("db", "bookshelf_development.sqlite3").exist?).to be false
        expect(Hanami.app.root.join("db", "bookshelf_main_development.sqlite3").exist?).to be true

        expect(output).to include "failed to create database db/bookshelf_development.sqlite3"
        expect(output).to include "app-db-err"

        expect(output).to include "database db/bookshelf_main_development.sqlite3 created"

        expect(command).to have_received(:exit).with(2).once
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
  end
end
