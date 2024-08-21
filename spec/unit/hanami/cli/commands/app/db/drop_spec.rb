# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Drop, :app_integration do
  subject(:command) { described_class.new(system_call: system_call, out: out) }

  let(:system_call) { Hanami::CLI::SystemCall.new }

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

    it "drops each database" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create)
      out.truncate(0)

      expect { command.call }
        .to change { File.exist?(@dir.join("db", "bookshelf_development.sqlite3")) }
        .and change { File.exist?(@dir.join("db", "bookshelf_main_development.sqlite3")) }
        .to false

      expect(output).to include "database db/bookshelf_development.sqlite3 dropped"
      expect(output).to include "database db/bookshelf_main_development.sqlite3 dropped"

      expect(command).not_to have_received(:exit)
    end

    it "drops the app database when given --app" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create)
      out.truncate(0)

      expect { command.call(app: true) }
        .to change {
          File.exist?(@dir.join("db", "bookshelf_development.sqlite3"))
        }
        .to false

      expect(File.exist?(@dir.join("db", "bookshelf_main_development.sqlite3"))).to be true

      expect(output).to include "database db/bookshelf_development.sqlite3 dropped"
      expect(output).not_to include "db/bookshelf_main_development.sqlite3"

      expect(command).not_to have_received(:exit)
    end

    it "drops a slice database when given --slice" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create)
      out.truncate(0)

      expect { command.call(slice: "main") }
        .to change {
          File.exist?(@dir.join("db", "bookshelf_main_development.sqlite3"))
        }
        .to false

      expect(File.exist?(@dir.join("db", "bookshelf_development.sqlite3"))).to be true

      expect(output).to include "database db/bookshelf_main_development.sqlite3 dropped"
      expect(output).not_to include "db/bookshelf_development.sqlite3"

      expect(command).not_to have_received(:exit)
    end

    it "does not drop databases that do not exist" do
      command.call

      expect(File.exist?(@dir.join("db", "bookshelf_development.sqlite3"))).to be false
      expect(File.exist?(@dir.join("db", "bookshelf_main_development.sqlite3"))).to be false

      expect(output).to include "database db/bookshelf_development.sqlite3 dropped"
      expect(output).to include "database db/bookshelf_main_development.sqlite3 dropped"

      expect(command).not_to have_received(:exit)
    end

    it "prints errors for any drops that fail and exits with non-zero status" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create)
      out.truncate(0)

      allow(File).to receive(:unlink).and_call_original
      allow(File).to receive(:unlink)
        .with(a_string_including("db/bookshelf_development.sqlite3"))
        .and_raise Errno::EACCES

      command.call

      expect(File.exist?(@dir.join("db", "bookshelf_development.sqlite3"))).to be true
      expect(File.exist?(@dir.join("db", "bookshelf_main_development.sqlite3"))).to be false

      expect(output).to include "failed to drop database db/bookshelf_development.sqlite3"
      expect(output).to include "Permission denied" # from Errno::EACCESS

      expect(output).to include "database db/bookshelf_main_development.sqlite3 dropped"

      expect(command).to have_received(:exit).with(1).once
    end
  end

  describe "postgres", :postgres do
    before do
      ENV["DATABASE_URL"] = "#{POSTGRES_BASE_URL}_app"
      ENV["MAIN__DATABASE_URL"] = "#{POSTGRES_BASE_URL}_main"
    end

    it "drops each database" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create)
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
      command.run_command(Hanami::CLI::Commands::App::DB::Create)
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
      command.run_command(Hanami::CLI::Commands::App::DB::Create, app: true)
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
  end

  describe "mysql", :mysql do
    before do
      ENV["DATABASE_URL"] = "#{MYSQL_BASE_URL}_app"
    end

    it "drops the database" do
      command.run_command(Hanami::CLI::Commands::App::DB::Create)
      out.truncate(0)

      expect { Hanami.app["db.gateway"].connection.test_connection }.not_to raise_error
      Hanami.app.stop :db

      command.call

      expect {
        Hanami.app["db.gateway"].connection.test_connection
      }.to raise_error Sequel::DatabaseConnectionError

      expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_app dropped"

      expect(command).not_to have_received(:exit)
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
      command.run_command(Hanami::CLI::Commands::App::DB::Create)
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
  end
end
