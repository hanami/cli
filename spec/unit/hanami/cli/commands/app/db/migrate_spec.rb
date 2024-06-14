# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Migrate, :app_integration do
  subject(:command) {
    described_class.new(
      out: out
    )
  }

  let(:out) { StringIO.new }
  let(:output) {
    out.rewind
    out.read
  }

  let(:dump_command) { instance_spy(Hanami::CLI::Commands::App::DB::Structure::Dump) }

  before do
    @env = ENV.to_h
    allow(Hanami::Env).to receive(:loaded?).and_return(false)

    allow(Hanami::CLI::Commands::App::DB::Structure::Dump).to receive(:new) { dump_command }
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
  end

  context "single db in app" do
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
    end

    before do
      ENV["DATABASE_URL"] = "sqlite://#{File.join(@dir, "app.db")}"
    end

    it "runs the migrations and dumps the structure" do
      command.call

      expect(output).to match /database.+migrated/

      expect(Hanami.app["relations.posts"].to_a).to eq []

      expect(dump_command).to have_received(:call).with(app: false, slice: nil)
      expect(dump_command).to have_received(:call).exactly(1).time
    end

    it "runs migrations to a specific target" do
      command.call # to add_body_to_posts
      expect(output).to match /database.+migrated/

      column_names = Hanami.app["db.gateway"].connection
        .execute("PRAGMA table_info(posts)").to_a
        .map { _1[1] }
      expect(column_names).to eq %w[id title body]

      command.call(target: "20240602201330") # back to create_posts
      expect(output).to match /database.+migrated/

      column_names = Hanami.app["db.gateway"].connection
        .execute("PRAGMA table_info(posts)").to_a
        .map { _1[1] }
      expect(column_names).to eq %w[id title] # no more body

      expect(Hanami.app["relations.posts"].to_a).to eq []
    end
  end

  context "single db with no migration files" do
    def before_prepare
      write "config/db/migrate/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "sqlite://#{File.join(@dir, "app.db")}"
    end

    it "does nothing" do
      command.call
      expect(output).to be_empty
    end
  end

  context "single db in slice" do
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
    end

    before do
      ENV["DATABASE_URL"] = "sqlite://#{File.join(@dir, "slice.db")}"
    end

    it "runs the migrations" do
      command.call

      expect(output).to match /database.+migrated/

      expect(Admin::Slice["relations.posts"].to_a).to eq []
    end

    it "runs the migrations and dumps the structure when the slice is specified" do
      command.call(slice: "admin")

      expect(output).to match /database.+migrated/

      expect(Admin::Slice["relations.posts"].to_a).to eq []

      expect(dump_command).to have_received(:call).with(app: false, slice: "admin")
      expect(dump_command).to have_received(:call).exactly(1).time
    end
  end

  context "dbs across app and slice" do
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

      write "app/relations/posts.rb", <<~RUBY
        module TestApp
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
      ENV["DATABASE_URL"] = "sqlite://#{File.join(@dir, "app.db")}"
      ENV["MAIN__DATABASE_URL"] = "sqlite://#{File.join(@dir, "main.db")}"
    end

    it "runs the migrations and dumps the structure for all databases" do
      command.call

      expect(output).to include "app.db migrated"
      expect(output).to include "main.db migrated"

      expect(Hanami.app["relations.posts"].to_a).to eq []
      expect(Main::Slice["relations.comments"].to_a).to eq []

      expect(dump_command).to have_received(:call).with(app: false, slice: nil)
      expect(dump_command).to have_received(:call).exactly(1).time
    end

    it "runs the migration and dumps the structure for the app" do
      command.call(app: true)

      expect(output).to include "app.db migrated"
      expect(output).not_to include "main.db migrated"

      expect(Hanami.app["relations.posts"].to_a).to eq []
      expect { Main::Slice["relations.comments"].to_a }.to raise_error Sequel::Error

      expect(dump_command).to have_received(:call).with(app: true, slice: nil)
      expect(dump_command).to have_received(:call).exactly(1).time
    end

    it "runs the migration and dumps the structure for a given slice" do
      command.call(slice: "main")

      expect(output).to include "main.db migrated"
      expect(output).not_to include "app.db migrated"

      expect(Main::Slice["relations.comments"].to_a).to eq []
      expect { Hanami.app["relations.posts"].to_a }.to raise_error Sequel::Error

      expect(dump_command).to have_received(:call).with(app: false, slice: "main")
      expect(dump_command).to have_received(:call).exactly(1).time
    end
  end

  context "multiple dbs across multiple slices" do
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
      ENV["ADMIN__DATABASE_URL"] = "sqlite://#{File.join(@dir, "admin.db")}"
      ENV["MAIN__DATABASE_URL"] = "sqlite://#{File.join(@dir, "main.db")}"
    end

    it "runs the migrations and dumps the structure for all databases" do
      command.call

      expect(output).to include "admin.db migrated"
      expect(output).to include "main.db migrated"

      expect(Admin::Slice["relations.posts"].to_a).to eq []
      expect(Main::Slice["relations.comments"].to_a).to eq []

      expect(dump_command).to have_received(:call).with(app: false, slice: nil)
      expect(dump_command).to have_received(:call).exactly(1).time
    end

    it "runs the migration and dumps the structure for a given slice" do
      command.call(slice: "admin")

      expect(output).to include "admin.db migrated"
      expect(output).not_to include "main.db migrated"

      expect(Admin::Slice["relations.posts"].to_a).to eq []
      expect { Main::Slice["relations.comments"].to_a }.to raise_error Sequel::Error

      expect(dump_command).to have_received(:call).with(app: false, slice: "admin")
      expect(dump_command).to have_received(:call).exactly(1).time
    end
  end

  context "multiple dbs across slices, each with the same database_url and config/db/ dirs" do
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
      ENV["ADMIN__DATABASE_URL"] = "sqlite://#{File.join(@dir, "confused.db")}"
      ENV["MAIN__DATABASE_URL"] = "sqlite://#{File.join(@dir, "confused.db")}"
    end

    it "prints a warning, and runs migrations from the first slice" do
      command.call

      expect(output).to match /WARNING:.+multiple slices.+Migrating database using "admin" slice only./m

      expect(output).to include "confused.db migrated"

      expect(Admin::Slice["relations.posts"].to_a).to eq []
      expect { Main::Slice["relations.comments"].to_a }.to raise_error Sequel::Error
    end
  end

  context "database with no config" do
    def before_prepare
      write "app/relations/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "sqlite://#{File.join(@dir, "app.db")}"
    end

    it "prints a warning, and does not migrate the database" do
      command.call

      expect(output).to match %{WARNING:.+no config/db/ directory.}
      expect(output).not_to include "migrated"
    end
  end
end
