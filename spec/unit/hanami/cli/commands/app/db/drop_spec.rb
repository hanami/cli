# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Drop, :app_integration do
  subject(:command) {
    described_class.new(
      system_call: system_call,
      test_env_executor: test_env_executor,
      out: out
    )
  }

  let(:system_call) { Hanami::CLI::SystemCall.new }
  let(:test_env_executor) { instance_spy(Hanami::CLI::InteractiveSystemCall) }
  let(:exit_double) { double(:exit_method) }

  let(:out) { StringIO.new }
  def output = out.string

  before do
    # Prevent the command from exiting the spec run in the case of unexpected system call failures
    allow(command).to receive(:exit)
    allow(exit_double).to receive(:call)
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

    it "drops each database" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create, command_exit: exit_double)
      out.truncate(0)

      expect { command.call }
        .to change { File.exist?(@dir.join("db", "app.sqlite3")) }
        .and change { File.exist?(@dir.join("db", "main.sqlite3")) }
        .to false

      expect(output).to include "database db/app.sqlite3 dropped"
      expect(output).to include "database db/main.sqlite3 dropped"

      expect(command).not_to have_received(:exit)
    end

    it "drops the app database when given --app" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create, command_exit: exit_double)
      out.truncate(0)

      expect { command.call(app: true) }
        .to change {
          File.exist?(@dir.join("db", "app.sqlite3"))
        }
        .to false

      expect(File.exist?(@dir.join("db", "main.sqlite3"))).to be true

      expect(output).to include "database db/app.sqlite3 dropped"
      expect(output).not_to include "db/main.sqlite3"

      expect(command).not_to have_received(:exit)
    end

    it "drops a slice database when given --slice" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create, command_exit: exit_double)
      out.truncate(0)

      expect { command.call(slice: "main") }
        .to change {
          File.exist?(@dir.join("db", "main.sqlite3"))
        }
        .to false

      expect(File.exist?(@dir.join("db", "app.sqlite3"))).to be true

      expect(output).to include "database db/main.sqlite3 dropped"
      expect(output).not_to include "db/app.sqlite3"

      expect(command).not_to have_received(:exit)
    end

    it "does not drop databases that do not exist" do
      command.call

      expect(File.exist?(@dir.join("db", "app.sqlite3"))).to be false
      expect(File.exist?(@dir.join("db", "main.sqlite3"))).to be false

      expect(output).to include "database db/app.sqlite3 dropped"
      expect(output).to include "database db/main.sqlite3 dropped"

      expect(command).not_to have_received(:exit)
    end

    it "prints errors for any drops that fail and exits with non-zero status" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create, command_exit: exit_double)
      out.truncate(0)

      allow(File).to receive(:unlink).and_call_original
      allow(File).to receive(:unlink)
        .with(a_string_including("db/app.sqlite3"))
        .and_raise Errno::EACCES

      command.call

      expect(File.exist?(@dir.join("db", "app.sqlite3"))).to be true
      expect(File.exist?(@dir.join("db", "main.sqlite3"))).to be false

      expect(output).to include "failed to drop database db/app.sqlite3"
      expect(output).to include "Permission denied" # from Errno::EACCESS

      expect(output).to include "database db/main.sqlite3 dropped"

      expect(command).to have_received(:exit).with(1).once
    end

    context "app and slice with gateways" do
      def before_prepare
        write "config/db/.keep", ""
        write "slices/main/config/db/.keep", ""

        ENV["DATABASE_URL__EXTRA"] = "sqlite://db/app_extra.sqlite3"
        ENV["MAIN__DATABASE_URL__EXTRA"] = "sqlite://db/main_extra.sqlite3"
      end

      before do
        command.run_command(Hanami::CLI::Commands::App::DB::Create, command_exit: exit_double)
        out.truncate(0)
      end

      it "drops the databases for all gateways" do
        expect { command.call }
          .to change { File.exist?(@dir.join("db", "app.sqlite3")) }.to(false)
          .and change { File.exist?(@dir.join("db", "app_extra.sqlite3")) }.to(false)
          .and change { File.exist?(@dir.join("db", "main.sqlite3")) }.to(false)
          .and change { File.exist?(@dir.join("db", "main_extra.sqlite3")) }.to(false)

        expect(output.strip).to eq(<<~TEXT.strip)
          => database db/app.sqlite3 dropped
          => database db/app_extra.sqlite3 dropped
          => database db/main.sqlite3 dropped
          => database db/main_extra.sqlite3 dropped
        TEXT

        expect(command).not_to have_received(:exit)
      end
    end

    context "app with gateways" do
      def before_prepare
        write "config/db/.keep", ""
        ENV["DATABASE_URL__EXTRA"] = "sqlite://db/app_extra.sqlite3"
      end

      before do
        command.run_command(Hanami::CLI::Commands::App::DB::Create, command_exit: exit_double)
        out.truncate(0)
      end

      it "drops the databases for all the app's gateways when given --app" do
        expect { command.call(app: true) }
          .to change { File.exist?(@dir.join("db", "app.sqlite3")) }.to(false)
          .and change { File.exist?(@dir.join("db", "app_extra.sqlite3")) }.to false

        expect(output).to include_in_order(
          "database db/app.sqlite3 dropped",
          "database db/app_extra.sqlite3 dropped"
        )

        expect(command).not_to have_received(:exit)
      end

      it "drops the database for an app's gateway when given --app and --gateway" do
        expect { command.call(app: true, gateway: "extra") }
          .to change { File.exist?(@dir.join("db", "app_extra.sqlite3")) }.to(false)
          .and not_change { File.exist?(@dir.join("db", "app.sqlite3")) }.from(true)

        expect(output).to include "database db/app_extra.sqlite3 dropped"
        expect(output).not_to include "database/app.sqlite3"
      end
    end

    context "slice with gateways" do
      def before_prepare
        write "slices/main/config/db/.keep", ""
        ENV["MAIN__DATABASE_URL__EXTRA"] = "sqlite://db/main_extra.sqlite3"
      end

      before do
        command.run_command(Hanami::CLI::Commands::App::DB::Create, command_exit: exit_double)
        out.truncate(0)
      end

      it "drops the databases for all the slice's gateways when given --slice" do
        expect { command.call(slice: "main") }
          .to change { File.exist?(@dir.join("db", "main.sqlite3")) }.to(false)
          .and change { File.exist?(@dir.join("db", "main_extra.sqlite3")) }.to false

        expect(output).to include_in_order(
          "database db/main.sqlite3 dropped",
          "database db/main_extra.sqlite3 dropped"
        )

        expect(command).not_to have_received(:exit)
      end

      it "drops the database for an app's gateway when given --app and --gateway" do
        expect { command.call(slice: "main", gateway: "extra") }
          .to change { File.exist?(@dir.join("db", "main_extra.sqlite3")) }.to(false)
          .and not_change { File.exist?(@dir.join("db", "main.sqlite3")) }.from(true)

        expect(output).to include "database db/main_extra.sqlite3 dropped"
        expect(output).not_to include "database/main.sqlite3"

        expect(command).not_to have_received(:exit)
      end
    end
  end

  describe "postgres", :postgres do
    before do
      ENV["DATABASE_URL"] = "#{POSTGRES_BASE_URL}_app"
      ENV["MAIN__DATABASE_URL"] = "#{POSTGRES_BASE_URL}_main"
    end

    it "drops each database" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create, command_exit: exit_double)
      out.truncate(0)

      expect { Hanami.app["db.gateway"].connection.test_connection }.not_to raise_error
      expect { Main::Slice["db.gateway"].connection.test_connection }.not_to raise_error
      Hanami.app.stop :db
      Main::Slice.stop :db

      command.call

      expect {
        Hanami.app["db.gateway"].connection.test_connection
      }.to raise_error Sequel::DatabaseConnectionError
      expect {
        Main::Slice["db.gateway"].connection.test_connection
      }.to raise_error Sequel::DatabaseConnectionError

      expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_app dropped"
      expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_main dropped"

      expect(command).not_to have_received(:exit)
    end

    it "drops the app database when given --app" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create, command_exit: exit_double)
      out.truncate(0)

      command.call(app: true)

      expect {
        Hanami.app["db.gateway"].connection.test_connection
      }.to raise_error Sequel::DatabaseConnectionError
      expect {
        Main::Slice["db.gateway"].connection.test_connection
      }.not_to raise_error

      expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_app dropped"
      expect(output).not_to include "#{POSTGRES_BASE_DB_NAME}_main"

      expect(command).not_to have_received(:exit)
    end

    it "drops a slice database when given --slice" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create)
      out.truncate(0)

      command.call(slice: "main")

      expect {
        Hanami.app["db.gateway"].connection.test_connection
      }.not_to raise_error
      expect {
        Main::Slice["db.gateway"].connection.test_connection
      }.to raise_error Sequel::DatabaseConnectionError

      expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_main dropped"
      expect(output).not_to include "#{POSTGRES_BASE_DB_NAME}_app"

      expect(command).not_to have_received(:exit)
    end

    it "does not drop databases that do not exist" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create, app: true, command_exit: exit_double)
      out.truncate(0)

      expect { Hanami.app["db.gateway"].connection.test_connection }.not_to raise_error
      Hanami.app.stop :db

      command.call

      expect {
        Hanami.app["db.gateway"].connection.test_connection
      }.to raise_error Sequel::DatabaseConnectionError
      expect {
        Main::Slice["db.gateway"].connection.test_connection
      }.to raise_error Sequel::DatabaseConnectionError

      expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_app dropped"
      expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_main dropped"

      expect(command).not_to have_received(:exit)
    end

    it "prints errors for any drop commands that fail and exits with non-zero status" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create)
      out.truncate(0)

      allow(system_call).to receive(:call).and_call_original
      allow(system_call)
        .to receive(:call)
        .with(a_string_matching(/dropdb.+_app/), anything)
        .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 2, out: "", err: "app-db-err")

      command.call

      expect { Hanami.app["db.gateway"].connection.test_connection }.not_to raise_error

      expect(output).to include "failed to drop database #{POSTGRES_BASE_DB_NAME}_app"
      expect(output).to include "app-db-err"

      expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_main dropped"

      expect(command).to have_received(:exit).with(2).once
    end

    it "raises exception when DB existence check fails" do
      allow(system_call).to receive(:call).and_call_original
      allow(system_call)
        .to receive(:call)
        .with(a_string_matching(/\\list.+_app/), anything)
        .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 2, out: "", err: "app-db-err")

      expect { command.call }.to raise_error(Hanami::CLI::Error)
    end
  end

  describe "mysql", :mysql do
    before do
      ENV["DATABASE_URL"] = "#{MYSQL_BASE_URL}_app"
    end

    it "drops the database" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create, command_exit: exit_double)
      out.truncate(0)

      expect { Hanami.app["db.gateway"].connection.test_connection }.not_to raise_error
      Hanami.app.stop :db

      command.call

      expect {
        Hanami.app["db.gateway"].connection.test_connection
      }.to raise_error Sequel::DatabaseConnectionError

      expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_app dropped"

      expect(command).not_to have_received(:exit)
      expect(exit_double).not_to have_received(:call)
    end

    it "does not drop a database that does not exist" do
      command.call

      expect {
        Hanami.app["db.gateway"].connection.test_connection
      }.to raise_error Sequel::DatabaseConnectionError

      expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_app dropped"

      expect(command).not_to have_received(:exit)
    end

    it "prints errors for any drop commands that fail and exits with non-zero status" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create, command_exit: exit_double)
      out.truncate(0)

      allow(system_call).to receive(:call).and_call_original
      allow(system_call)
        .to receive(:call)
        .with(a_string_matching(/-e "DROP DATABASE/), anything)
        .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 2, out: "", err: "app-db-err")

      command.call

      expect { Hanami.app["db.gateway"].connection.test_connection }.not_to raise_error

      expect(output).to include "failed to drop database #{POSTGRES_BASE_DB_NAME}_app"
      expect(output).to include "app-db-err"

      expect(command).to have_received(:exit).with(2).once
    end

    it "prints errors when check for DB existence fails" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create, command_exit: exit_double)
      out.truncate(0)

      allow(system_call).to receive(:call).and_call_original
      allow(system_call)
        .to receive(:call)
        .with(a_string_matching(/-e "SHOW DATABASES/), anything)
        .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 2, out: "", err: "app-db-err")

      expect {
        command.call
      }.to raise_error(Hanami::CLI::DatabaseExistenceCheckError)
    end
  end

  describe "automatic test env execution" do
    before do
      ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
    end

    around do |example|
      as_hanami_cli_with_args(%w[db drop]) { example.run }
    end

    it "re-executes the command in test env when run with development env" do
      command.call(env: "development")

      expect(test_env_executor).to have_received(:call).with(
        "bundle exec hanami",
        "db", "drop",
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
