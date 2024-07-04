# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Migrate, :app_integration do
  subject(:command) { described_class.new(out: out) }

  let(:out) { StringIO.new }
  def output; out.string; end

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

      write "app/relations/posts.rb", <<~RUBY
        module TestApp
          module Relations
            class Posts < Hanami::DB::Relation
              schema :posts, infer: true
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

      write "slices/main/relations/comments.rb", <<~RUBY
        module Main
          module Relations
            class Comments < Hanami::DB::Relation
              schema :comments, infer: true
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

        expect(Hanami.app["relations.posts"].to_a).to eq []
        expect(Main::Slice["relations.comments"].to_a).to eq []

        expect(dump_command).to have_received(:call).with(hash_including(app: false, slice: nil))
        expect(dump_command).to have_received(:call).once

        expect(output).to include "database db/app.sqlite3 migrated"
        expect(output).to include "database db/main.sqlite3 migrated"
      end

      it "runs the migration and dumps the structure for the app db when given --app" do
        command.call(app: true)

        expect(Hanami.app["relations.posts"].to_a).to eq []
        expect { Main::Slice["relations.comments"].to_a }.to raise_error Sequel::Error

        expect(dump_command).to have_received(:call).with(hash_including(app: true, slice: nil))
        expect(dump_command).to have_received(:call).once

        expect(output).to include "database db/app.sqlite3 migrated"
        expect(output).not_to include "main.sqlite3"
      end

      it "runs the migration and dumps the structure for a slice db when given --slice" do
        command.call(slice: "main")

        expect(Main::Slice["relations.comments"].to_a).to eq []
        expect { Hanami.app["relations.posts"].to_a }.to raise_error Sequel::Error

        expect(dump_command).to have_received(:call).with(hash_including(app: false, slice: "main"))
        expect(dump_command).to have_received(:call).exactly(1).time

        expect(output).to include "database db/main.sqlite3 migrated"
        expect(output).not_to include "app.sqlite3"
      end

      it "runs migrations to a specific target" do
        column_names = -> {
          Hanami.app["db.gateway"].connection
            .fetch("PRAGMA table_info(posts)")
            .to_a.map { _1[:name] }
        }

        command.call # migrate to add_body_to_posts
        expect(column_names.()).to eq %w[id title body]

        command.call(target: "20240602201330") # migrate back to create_posts
        expect(column_names.()).to eq %w[id title] # no more body

        expect(Hanami.app["relations.posts"].to_a).to eq []
      end

      it "does not dump the database structure when given --dump=false" do
        command.call(dump: false)

        expect(dump_command).not_to have_received(:call)
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

        expect(Hanami.app["relations.posts"].to_a).to eq []
        expect(Main::Slice["relations.comments"].to_a).to eq []

        expect(dump_command).to have_received(:call).with(hash_including(app: false, slice: nil))
        expect(dump_command).to have_received(:call).once

        expect(output).to include "database hanami_cli_test_app migrated"
        expect(output).to include "database hanami_cli_test_main migrated"
      end

      it "runs the migration and dumps the structure for the app db when given --app" do
        command.call(app: true)

        expect(output).to include "database hanami_cli_test_app migrated"
        expect(output).not_to include "hanami_cli_test_main"

        expect(Hanami.app["relations.posts"].to_a).to eq []
        expect { Main::Slice["relations.comments"].to_a }.to raise_error Sequel::Error

        expect(dump_command).to have_received(:call).with(hash_including(app: true, slice: nil))
        expect(dump_command).to have_received(:call).once
      end

      it "runs the migration and dumps the structure for a slice db when given --slice" do
        command.call(slice: "main")

        expect(Main::Slice["relations.comments"].to_a).to eq []
        expect { Hanami.app["relations.posts"].to_a }.to raise_error Sequel::Error

        expect(dump_command).to have_received(:call).with(hash_including(app: false, slice: "main"))
        expect(dump_command).to have_received(:call).exactly(1).time

        expect(output).to include "database hanami_cli_test_main migrated"
        expect(output).not_to include "hanami_cli_test_app"
      end

      it "runs migrations to a specific target" do
        column_names = -> {
          Hanami.app["db.gateway"].connection
            .fetch("SELECT column_name FROM information_schema.columns WHERE table_name = 'posts'")
            .to_a.map { _1[:column_name] }
        }

        command.call # migrate to add_body_to_posts
        expect(column_names.()).to eq %w[id title body]

        command.call(target: "20240602201330") # migrate back to create_posts
        expect(column_names.()).to eq %w[id title] # no more body

        expect(Hanami.app["relations.posts"].to_a).to eq []
      end

      it "does not dump the database structure when given --dump=false" do
        command.call(dump: false)

        expect(dump_command).not_to have_received(:call)
      end
    end
  end

  context "no migration files" do
    def before_prepare
      write "config/db/migrate/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
      db_create
    end

    it "does nothing" do
      command.call
      expect(output).to be_empty
    end
  end

  context "multiple dbs with identical database_url" do
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

      write "slices/admin/relations/posts.rb", <<~RUBY
        module Admin
          module Relations
            class Posts < Hanami::DB::Relation
              schema :posts, infer: true
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

      write "slices/main/relations/comments.rb", <<~RUBY
        module Main
          module Relations
            class Comments < Hanami::DB::Relation
              schema :comments, infer: true
            end
          end
        end
      RUBY
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
        'Migrating database using "admin" slice only',
        "database db/confused.sqlite3 migrated"
      )

      expect(Admin::Slice["relations.posts"].to_a).to eq []
      expect { Main::Slice["relations.comments"].to_a }.to raise_error Sequel::Error
    end
  end

  context "no db config dir" do
    def before_prepare
      write "app/relations/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
    end

    it "prints a warning, and does not migrate the database" do
      command.call

      expect(output).to match %{WARNING:.+no config/db/ directory.}
      expect(output).not_to include "migrated"
    end
  end
end
