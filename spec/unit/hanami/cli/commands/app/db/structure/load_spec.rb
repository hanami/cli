# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Structure::Load, :app_integration do
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
      write "db/.keep", ""

      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/db/migrate/20240602201330_create_posts.rb", <<~RUBY
        ROM::SQL.migration do
          change do
            create_table :posts do
              primary_key :id
              column :title, :text, null: false
            end
          end
        end
      RUBY

      write "slices/main/config/db/migrate/20240602201330_create_comments.rb", <<~RUBY
        ROM::SQL.migration do
          change do
            create_table :comments do
              primary_key :id
              column :body, :text, null: false
            end
          end
        end
      RUBY

      require "hanami/setup"
      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end

    Dir.chdir(@dir)
  end

  def db_structure_dump
    command.run_command(Hanami::CLI::Commands::App::DB::Create, command_exit: exit_double)
    command.run_command(Hanami::CLI::Commands::App::DB::Migrate)

    # `db migrate` establishes a connection to the database, which will prevent it from being
    # dropped. To allow the drop, disconnect from the database by stopping the :db provider
    # (which requires starting it first, a prerequesite for it to be stopped).
    Hanami.app.start :db and Hanami.app.stop :db
    Main::Slice.start :db and Main::Slice.stop :db

    command.run_command(Hanami::CLI::Commands::App::DB::Drop)
    command.run_command(Hanami::CLI::Commands::App::DB::Create, command_exit: exit_double)

    out.truncate(0)
  end

  describe "sqlite" do
    before do
      ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
      ENV["MAIN__DATABASE_URL"] = "sqlite://db/main.sqlite3"
      db_structure_dump
    end

    it "loads the structure for each db" do
      expect { command.call }
        .to change { Hanami.app["db.gateway"].connection.tables.include?(:posts) }
        .and change { Main::Slice["db.gateway"].connection.tables.include?(:comments) }
        .to true

      expect(output).to include_in_order(
        "db/app.sqlite3 structure loaded from config/db/structure.sql",
        "db/main.sqlite3 structure loaded from slices/main/config/db/structure.sql"
      )
    end

    context "app with gateways" do
      def before_prepare
        ENV["DATABASE_URL__EXTRA"] = "sqlite://db/app_extra.sqlite3"

        write "config/db/extra_migrate/20240602201330_create_users.rb", <<~RUBY
          ROM::SQL.migration do
            change do
              create_table :users do
                primary_key :id
                column :name, :text, null: false
              end
            end
          end
        RUBY
      end

      it "loads the structure for all the app's gateways when given --app" do
        expect { command.call(app: true) }
          .to change { Hanami.app["db.gateways.default"].connection.tables.include?(:posts) }
          .and change { Hanami.app["db.gateways.extra"].connection.tables.include?(:users) }
          .to true

        expect(output).to include_in_order(
          "db/app.sqlite3 structure loaded from config/db/structure.sql in",
          "db/app_extra.sqlite3 structure loaded from config/db/extra_structure.sql in"
        )
      end

      it "loads the structure for a specific gateway database when given --app and --gateway" do
        expect { command.call(app: true, gateway: "extra") }
          .to change { Hanami.app["db.gateways.extra"].connection.tables.include?(:users) }
          .to(true)
          .and not_change { Hanami.app["db.gateways.default"].connection.tables.include?(:posts) }
          .from false

        expect(output).to include "db/app_extra.sqlite3 structure loaded from config/db/extra_structure.sql in"
        expect(output).not_to include "db/app.sqlite3"
      end
    end

    context "slice with gateways" do
      def before_prepare
        ENV["MAIN__DATABASE_URL__EXTRA"] = "sqlite://db/main_extra.sqlite3"

        write "slices/main/config/db/extra_migrate/20240602201330_create_users.rb", <<~RUBY
          ROM::SQL.migration do
            change do
              create_table :users do
                primary_key :id
                column :name, :text, null: false
              end
            end
          end
        RUBY
      end

      it "loads the structure for all the slice's gateways when given --slice" do
        expect { command.call(slice: "main") }
          .to change { Main::Slice["db.gateways.default"].connection.tables.include?(:comments) }
          .and change { Main::Slice["db.gateways.extra"].connection.tables.include?(:users) }
          .to true

        expect(output).to include_in_order(
          "db/main.sqlite3 structure loaded from slices/main/config/db/structure.sql in",
          "db/main_extra.sqlite3 structure loaded from slices/main/config/db/extra_structure.sql in"
        )
      end

      it "loads the structure for a specific gateway database when given --slice and --gateway" do
        expect { command.call(slice: "main", gateway: "extra") }
          .to change { Main::Slice["db.gateways.extra"].connection.tables.include?(:users) }
          .to(true)
          .and not_change { Main::Slice["db.gateways.default"].connection.tables.include?(:comments) }
          .from false

        expect(output).to include "db/main_extra.sqlite3 structure loaded from slices/main/config/db/extra_structure.sql in"
        expect(output).not_to include "db/main.sqlite3"
      end
    end
  end

  describe "postgres", :postgres do
    before do
      ENV["DATABASE_URL"] = "#{POSTGRES_BASE_URL}_app"
      ENV["MAIN__DATABASE_URL"] = "#{POSTGRES_BASE_URL}_main"
      db_structure_dump
    end

    it "loads the structure for each db" do
      expect { command.call }
        .to change { Hanami.app["db.gateway"].connection.tables.include?(:posts) }
        .and change { Main::Slice["db.gateway"].connection.tables.include?(:comments) }
        .to true

      expect(output).to include_in_order(
        "#{POSTGRES_BASE_DB_NAME}_app structure loaded from config/db/structure.sql",
        "#{POSTGRES_BASE_DB_NAME}_main structure loaded from slices/main/config/db/structure.sql"
      )
    end

    it "loads the structure for the app db when given --app" do
      expect { command.call(app: true) }
        .to change { Hanami.app["db.gateway"].connection.tables.include?(:posts) }
        .to(true)
        .and not_change { Main::Slice["db.gateway"].connection.tables.include?(:comments) }
        .from false

      expect(output).to include "#{POSTGRES_BASE_DB_NAME}_app structure loaded from config/db/structure.sql"
      expect(output).not_to include "#{POSTGRES_BASE_DB_NAME}_main"
    end

    it "loads the structure for a slice db when given --slice" do
      expect { command.call(slice: "main") }
        .to change { Main::Slice["db.gateway"].connection.tables.include?(:comments) }
        .to(true)
        .and not_change { Hanami.app["db.gateway"].connection.tables.include?(:posts) }
        .from false

      expect(output).to include "#{POSTGRES_BASE_DB_NAME}_main structure loaded from slices/main/config/db/structure.sql"
      expect(output).not_to include "#{POSTGRES_BASE_DB_NAME}_app"
    end

    it "prints errors for any dumps that fail and exits with non-zero status" do
      # Fail to load the app db
      allow(system_call).to receive(:call).and_call_original
      allow(system_call)
        .to receive(:call)
        .with(a_string_including("#{POSTGRES_BASE_DB_NAME}_app"), anything)
        .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 2, out: "", err: "app-load-err")

      command.call

      expect(Hanami.app["db.gateway"].connection.tables.include?(:posts)).to be false
      expect(Main::Slice["db.gateway"].connection.tables.include?(:comments)).to be true

      expect(output).to include %("#{POSTGRES_BASE_DB_NAME}_app structure loaded from config/db/structure.sql" FAILED)
      expect(output).to include "#{POSTGRES_BASE_DB_NAME}_main structure loaded from slices/main/config/db/structure.sql"

      expect(command).to have_received(:exit).with 2
    end
  end

  describe "mysql", :mysql do
    before do
      ENV["DATABASE_URL"] = "#{MYSQL_BASE_URL}_app"
      db_structure_dump
    end

    it "loads the structure for each db" do
      expect { command.call }
        .to change { Hanami.app["db.gateway"].connection.tables.include?(:posts) }
        .to true

      expect(output).to include(
        "#{MYSQL_BASE_DB_NAME}_app structure loaded from config/db/structure.sql",
      )
    end

    it "prints errors for any dumps that fail and exits with non-zero status" do
      # Fail to load the app db
      allow(system_call).to receive(:call).and_call_original
      allow(system_call)
        .to receive(:call)
        .with(a_string_including("#{MYSQL_BASE_DB_NAME}_app"), anything)
        .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 2, out: "", err: "app-load-err")

      command.call

      expect(Hanami.app["db.gateway"].connection.tables.include?(:posts)).to be false

      expect(output).to include %("#{MYSQL_BASE_DB_NAME}_app structure loaded from config/db/structure.sql" FAILED)

      expect(command).to have_received(:exit).with 2
    end
  end

  describe "automatic test env execution" do
    before do
      ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
    end

    around do |example|
      as_hanami_cli_with_args(%w[db structure load]) { example.run }
    end

    it "re-executes the command in test env when run with development env" do
      command.call(env: "development")

      expect(test_env_executor).to have_received(:call).with(
        "bundle exec hanami",
        "db", "structure", "load",
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
