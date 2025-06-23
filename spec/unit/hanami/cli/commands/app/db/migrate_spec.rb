# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Migrate, :app_integration do
  subject(:command) { described_class.new(out: out, test_env_executor: test_env_executor) }

  let(:out) { StringIO.new }
  def output = out.string

  let(:test_env_executor) { instance_spy(Hanami::CLI::InteractiveSystemCall) }

  let(:dump_command) { instance_spy(Hanami::CLI::Commands::App::DB::Structure::Dump) }

  before do
    allow(Hanami::CLI::Commands::App::DB::Structure::Dump).to receive(:new) { dump_command }
  end

  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)
  end

  after do
    ENV.replace(@env)
  end

  def db_create
    command.run_command(Hanami::CLI::Commands::App::DB::Create)
    out.truncate(0)
  end

  before do
    with_directory(@dir = make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
            config.logger.stream = File::NULL
          end
        end
      RUBY

      require "hanami/setup"
      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end

    # Execute the test inside the context of the created app. This is a necessary to locate SQLite
    # databases specified with relative paths.
    Dir.chdir(@dir)
  end

  context "migrations present" do
    def before_prepare
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

      write "config/db/migrate/20240602211330_add_body_to_posts.rb", <<~RUBY
        ROM::SQL.migration do
          change do
            alter_table :posts do
              add_column :body, :text, null: false
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
    end

    describe "sqlite" do
      before do
        ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
        ENV["MAIN__DATABASE_URL"] = "sqlite://db/main.sqlite3"
        db_create
      end

      it "runs the migrations and dumps the structure for all databases" do
        command.call

        expect(Hanami.app["db.gateway"].connection.tables).to include :posts
        expect(Main::Slice["db.gateway"].connection.tables).to include :comments

        expect(dump_command).to have_received(:call).with(hash_including(app: false, slice: nil))
        expect(dump_command).to have_received(:call).once

        expect(output).to include_in_order(
          "database db/app.sqlite3 migrated",
          "database db/main.sqlite3 migrated"
        )
      end

      it "runs the migration and dumps the structure for the app db when given --app" do
        command.call(app: true)

        expect(Hanami.app["db.gateway"].connection.tables).to include :posts
        expect(Main::Slice["db.gateway"].connection.tables).not_to include :comments

        expect(dump_command).to have_received(:call).with(hash_including(app: true, slice: nil))
        expect(dump_command).to have_received(:call).once

        expect(output).to include "database db/app.sqlite3 migrated"
        expect(output).not_to include "main.sqlite3"
      end

      it "runs the migration and dumps the structure for a slice db when given --slice" do
        command.call(slice: "main")

        expect(Main::Slice["db.gateway"].connection.tables).to include :comments
        expect(Hanami.app["db.gateway"].connection.tables).not_to include :posts

        expect(dump_command).to have_received(:call).with(hash_including(app: false, slice: "main"))
        expect(dump_command).to have_received(:call).exactly(1).time

        expect(output).to include "database db/main.sqlite3 migrated"
        expect(output).not_to include "app.sqlite3"
      end

      it "runs migrations to a specific target" do
        columns = -> { Hanami.app["db.gateway"].connection.schema(:posts).map(&:first) }

        command.call # migrate to add_body_to_posts
        expect(columns.()).to eq %i[id title body]

        command.call(target: "20240602201330") # migrate back to create_posts
        expect(columns.()).to eq %i[id title] # no more body

        expect(Hanami.app["db.gateway"].connection.tables).to include :posts
      end

      it "does not dump the database structure when given --dump=false" do
        command.call(dump: false)

        expect(dump_command).not_to have_received(:call)
      end

      context "app with multiple gateways" do
        def before_prepare
          super

          ENV["DATABASE_URL__EXTRA"] = "sqlite://db/app_extra.sqlite3"

          write "config/db/extra_migrate/20240602201330_create_comments.rb", <<~RUBY
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

        it "runs the migration and dumps the structure for all the app's gateways when given --app" do
          command.call(app: true)

          expect(Hanami.app["db.gateways.default"].connection.tables).to include :posts
          expect(Hanami.app["db.gateways.extra"].connection.tables).to include :users

          expect(dump_command).to have_received(:call).with(hash_including(app: true, slice: nil))
          expect(dump_command).to have_received(:call).once

          expect(output).to include_in_order(
            "database db/app.sqlite3 migrated in",
            "database db/app_extra.sqlite3 migrated in"
          )
        end

        it "runs the migration and dumps the structure for a single app gateway when --app and --gateway" do
          command.call(app: true, gateway: "extra")

          expect(Hanami.app["db.gateways.extra"].connection.tables).to include :users
          expect(Hanami.app["db.gateways.default"].connection.tables).not_to include :posts

          expect(dump_command).to have_received(:call).with(hash_including(app: true, slice: nil, gateway: "extra"))
          expect(dump_command).to have_received(:call).once

          expect(output).to include "database db/app_extra.sqlite3 migrated in"
          expect(output).not_to include "db/app.sqlite3"
        end
      end

      context "slice with multiple gateways" do
        def before_prepare
          super

          ENV["MAIN__DATABASE_URL__EXTRA"] = "sqlite://db/main_extra.sqlite3"

          write "slices/main/config/db/extra_migrate/20240602201330_create_comments.rb", <<~RUBY
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

        it "runs the migration and dumps the structure for all the slices's gateways when given --slice" do
          command.call(slice: "main")

          expect(Main::Slice["db.gateways.default"].connection.tables).to include :comments
          expect(Main::Slice["db.gateways.extra"].connection.tables).to include :users

          expect(dump_command).to have_received(:call).with(hash_including(slice: "main"))
          expect(dump_command).to have_received(:call).once

          expect(output).to include_in_order(
            "database db/main.sqlite3 migrated in",
            "database db/main_extra.sqlite3 migrated in"
          )
        end

        it "runs the migration and dumps the structure for a single slice gateway when --slice and --gateway" do
          command.call(slice: "main", gateway: "extra")

          expect(Main::Slice["db.gateways.extra"].connection.tables).to include :users
          expect(Main::Slice["db.gateways.default"].connection.tables).not_to include :comments

          expect(dump_command).to have_received(:call).with(hash_including(slice: "main", gateway: "extra"))
          expect(dump_command).to have_received(:call).once

          expect(output).to include "database db/main_extra.sqlite3 migrated in"
          expect(output).not_to include "db/main.sqlite3"
        end
      end
    end

    describe "postgres", :postgres do
      before do
        ENV["DATABASE_URL"] = "#{POSTGRES_BASE_URL}_app"
        ENV["MAIN__DATABASE_URL"] = "#{POSTGRES_BASE_URL}_main"
        db_create
      end

      it "runs the migrations and dumps the structure for all databases" do
        command.call

        expect(Hanami.app["db.gateway"].connection.tables).to include :posts
        expect(Main::Slice["db.gateway"].connection.tables).to include :comments

        expect(dump_command).to have_received(:call).with(hash_including(app: false, slice: nil))
        expect(dump_command).to have_received(:call).once

        expect(output).to include_in_order(
          "database #{POSTGRES_BASE_DB_NAME}_app migrated",
          "database #{POSTGRES_BASE_DB_NAME}_main migrated"
        )
      end

      it "runs the migration and dumps the structure for the app db when given --app" do
        command.call(app: true)

        expect(Hanami.app["db.gateway"].connection.tables).to include :posts
        expect(Main::Slice["db.gateway"].connection.tables).not_to include :comments

        expect(dump_command).to have_received(:call).with(hash_including(app: true, slice: nil))
        expect(dump_command).to have_received(:call).once

        expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_app migrated"
        expect(output).not_to include "#{POSTGRES_BASE_DB_NAME}_main"
      end

      it "runs the migration and dumps the structure for a slice db when given --slice" do
        command.call(slice: "main")

        expect(Main::Slice["db.gateway"].connection.tables).to include :comments
        expect(Hanami.app["db.gateway"].connection.tables).not_to include :posts

        expect(dump_command).to have_received(:call).with(hash_including(app: false, slice: "main"))
        expect(dump_command).to have_received(:call).exactly(1).time

        expect(output).to include "database #{POSTGRES_BASE_DB_NAME}_main migrated"
        expect(output).not_to include "#{POSTGRES_BASE_DB_NAME}_app"
      end

      it "runs migrations to a specific target" do
        columns = -> { Hanami.app["db.gateway"].connection.schema(:posts).map(&:first) }

        command.call # migrate to add_body_to_posts
        expect(columns.()).to eq %i[id title body]

        command.call(target: "20240602201330") # migrate back to create_posts
        expect(columns.()).to eq %i[id title] # no more body

        expect(Hanami.app["db.gateway"].connection.tables).to include :posts
      end

      it "does not dump the database structure when given --dump=false" do
        command.call(dump: false)

        expect(dump_command).not_to have_received(:call)
      end
    end
  end

  context "db used across slices, with one slice containing config/db/" do
    def before_prepare
      write "slices/admin/config/db/migrate/20240602201330_create_posts.rb", <<~RUBY
        ROM::SQL.migration do
          change do
            create_table :posts do
              primary_key :id
              column :title, :text, null: false
            end
          end
        end
      RUBY

      write "slices/admin/relations/.keep", ""
      write "slices/main/relations/.keep", ""
    end

    before do
      ENV["ADMIN__DATABASE_URL"] = "sqlite://db/shared.sqlite3"
      ENV["MAIN__DATABASE_URL"] = "sqlite://db/shared.sqlite3"
      db_create
    end

    it "migrates the database using the slice with config/db/" do
      command.call

      expect(output).to include "database db/shared.sqlite3 migrated"
      expect(output).not_to include "WARNING"

      expect(Admin::Slice["db.gateway"].connection.tables).to include :posts
    end
  end

  context "db used across slices, with multiple slices containing a config/db/" do
    def before_prepare
      write "slices/admin/config/db/migrate/20240602201330_create_posts.rb", <<~RUBY
        ROM::SQL.migration do
          change do
            create_table :posts do
              primary_key :id
              column :title, :text, null: false
            end
          end
        end
      RUBY

      write "slices/main/config/db/migrate/20240602201330_create_users.rb", <<~RUBY
        ROM::SQL.migration do
          change do
            create_table :comments do
              primary_key :id
              column :body, :text, null: false
            end
          end
        end
      RUBY

      write "slices/admin/relations/.keep", ""
      write "slices/main/relations/.keep", ""
    end

    before do
      ENV["ADMIN__DATABASE_URL"] = "sqlite://db/confused.sqlite3"
      ENV["MAIN__DATABASE_URL"] = "sqlite://db/confused.sqlite3"
      db_create
    end

    it "prints a warning before running migrations from the first slice only" do
      command.call

      expect(output).to include_in_order(
        "WARNING: Database db/confused.sqlite3 is configured for multiple config/db/ directories",
        "- slices/admin/config/db",
        "- slices/main/config/db",
        'Using config in "admin" slice only',
        "database db/confused.sqlite3 migrated"
      )

      expect(Admin::Slice["db.gateway"].connection.tables).to include :posts
      expect(Main::Slice["db.gateway"].connection.tables).not_to include :comments
    end
  end

  context "no db/config/" do
    def before_prepare
      write "app/relations/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
    end

    it "prints a warning, and does not migrate the database" do
      command.call

      expect(output).to include(
        "WARNING: Database db/app.sqlite3 expects the folder config/db/ to exist but it does not."
      )
      expect(output).not_to include "migrated"
    end
  end

  context "multiple slices with matching gateways, and no duplicate config/db/ gateway migrate dirs" do
    def before_prepare
      write "slices/admin/config/db/posts_migrate/20240602201330_create_posts.rb", <<~RUBY
        ROM::SQL.migration do
          change do
            create_table :posts do
              primary_key :id
              column :title, :text, null: false
            end
          end
        end
      RUBY

      write "slices/main/config/db/comments_migrate/20240602201330_create_users.rb", <<~RUBY
        ROM::SQL.migration do
          change do
            create_table :comments do
              primary_key :id
              column :body, :text, null: false
            end
          end
        end
      RUBY

      write "slices/admin/relations/.keep", ""
      write "slices/main/relations/.keep", ""
    end

    before do
      ENV["ADMIN__DATABASE_URL__POSTS"] = "sqlite://db/posts.sqlite3"
      ENV["ADMIN__DATABASE_URL__COMMENTS"] = "sqlite://db/comments.sqlite3"
      ENV["MAIN__DATABASE_URL__POSTS"] = "sqlite://db/posts.sqlite3"
      ENV["MAIN__DATABASE_URL__COMMENTS"] = "sqlite://db/comments.sqlite3"
      db_create
    end

    it "migrates the database using the slice with config/db/" do
      command.call

      expect(output).to include "database db/comments.sqlite3 migrated"
      expect(output).to include "database db/posts.sqlite3 migrated"
      puts output
      expect(output).not_to include "WARNING"

      expect(Admin::Slice["db.gateways.posts"].connection.tables).to include :posts
      expect(Admin::Slice["db.gateways.comments"].connection.tables).to include :comments
    end
  end

  context "multiple slices with matching gateways, but duplicate config/db/ gateway migrate dirs" do
    def before_prepare
      write "slices/admin/config/db/posts_migrate/20240602201330_create_posts.rb", <<~RUBY
        ROM::SQL.migration do
          change do
            create_table :posts do
              primary_key :id
              column :title, :text, null: false
            end
          end
        end
      RUBY

      # Duplicated from admin
      write "slices/main/config/db/posts_migrate/20240602201330_create_posts.rb", <<~RUBY
        ROM::SQL.migration do
          change do
            create_table :posts do
              primary_key :id
              column :title, :text, null: false
            end
          end
        end
      RUBY

      write "slices/main/config/db/comments_migrate/20240602201330_create_users.rb", <<~RUBY
        ROM::SQL.migration do
          change do
            create_table :comments do
              primary_key :id
              column :body, :text, null: false
            end
          end
        end
      RUBY

      write "slices/admin/relations/.keep", ""
      write "slices/main/relations/.keep", ""
    end

    before do
      ENV["ADMIN__DATABASE_URL__POSTS"] = "sqlite://db/posts.sqlite3"
      ENV["ADMIN__DATABASE_URL__COMMENTS"] = "sqlite://db/comments.sqlite3"
      ENV["MAIN__DATABASE_URL__POSTS"] = "sqlite://db/posts.sqlite3"
      ENV["MAIN__DATABASE_URL__COMMENTS"] = "sqlite://db/comments.sqlite3"
      db_create
    end

    it "prints a warning before running the migrations from the first config dir only" do
      command.call

      expect(output).to include_in_order(
        "WARNING: Database db/posts.sqlite3 is configured for multiple config/db/ directories:",
        "- slices/admin/config/db",
        "- slices/main/config/db",
        %(Using config in "admin" slice only.),
        "database db/comments.sqlite3 migrated",
        "database db/posts.sqlite3 migrated"
      )

      expect(Admin::Slice["db.gateways.posts"].connection.tables).to include :posts
      expect(Admin::Slice["db.gateways.comments"].connection.tables).to include :comments
    end
  end

  context "no db/config/migrate/" do
    def before_prepare
      write "app/relations/.keep", ""
      write "config/db/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
    end

    it "prints a warning, and does not migrate the database" do
      command.call

      expect(output).to include(
        "WARNING: Database db/app.sqlite3 expects migrations to be located within config/db/migrate/ but that folder does not exist."
      )
      expect(output).to include("No database migrations can be run for this database.")
      expect(output).not_to include "migrated"
    end
  end

  context "empty db/config/migrate/" do
    def before_prepare
      write "app/relations/.keep", ""
      write "config/db/.keep", ""
      write "config/db/migrate/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
      db_create
    end

    it "prints a warning, and does not migrate the database" do
      command.call

      expect(output).to include(
        "NOTE: Empty database migrations folder (config/db/migrate/) for db/app.sqlite3"
      )
      expect(output).not_to include "migrated"
    end
  end

  describe "automatic test env execution" do
    before do
      ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
      db_create
    end

    around do |example|
      as_hanami_cli_with_args(%w[db migrate]) { example.run }
    end

    it "re-executes the command in test env when run with development env" do
      command.call(env: "development")

      expect(test_env_executor).to have_received(:call).with(
        "bundle exec hanami",
        "db", "migrate",
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
