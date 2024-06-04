# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Version, :app_integration do
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
  end

  def migrate
    command.run_command(Hanami::CLI::Commands::App::DB::Migrate)
    out.truncate(0)
  end

  context "db in app" do
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

      write "app/relations/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "sqlite://#{File.join(@dir, "app.db")}"
    end

    it "prints the version" do
      migrate

      command.call

      expect(output).to include "app.db current schema version is 20240602211330_add_body_to_posts"
    end
  end

  context "multiple dbs" do
    def before_prepare
      write "config/db/migrate/20240602191330_create_categories.rb", <<~RUBY
        ROM::SQL.migration do
          change do
            create_table :categories do
              primary_key :id
              column :name, :text, null: false
            end
          end
        end
      RUBY

      write "app/relations/.keep", ""

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

      write "slices/main/config/db/migrate/20240602211330_create_comments.rb", <<~RUBY
        ROM::SQL.migration do
          change do
            create_table :comments do
              primary_key :id
              column :body, :text, null: false
            end
          end
        end
      RUBY

      write "slices/main/relations/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "sqlite://#{File.join(@dir, "app.db")}"
      ENV["ADMIN__DATABASE_URL"] = "sqlite://#{File.join(@dir, "admin.db")}"
      ENV["MAIN__DATABASE_URL"] = "sqlite://#{File.join(@dir, "main.db")}"
    end

    it "prints the versions for all databases" do
      migrate

      command.call

      expect(output).to include "app.db current schema version is 20240602191330_create_categories"
      expect(output).to include "admin.db current schema version is 20240602201330_create_posts"
      expect(output).to include "main.db current schema version is 20240602211330_create_comments"

      # Ordering of lines
      expect(output).to match /app.db.+admin.db.+main.db/m
    end

    it "prints the version of the app db only when given --app" do
      migrate

      command.call(app: true)

      expect(output).to include "app.db current schema version is 20240602191330_create_categories"
      expect(output).not_to include "admin.db"
      expect(output).not_to include "main.db"
    end

    it "prints the version of a slice when given --slice" do
      migrate

      command.call(slice: "admin")

      expect(output).to include "admin.db current schema version is 20240602201330_create_posts"
      expect(output).not_to include "app.db"
      expect(output).not_to include "main.db"
    end
  end
end
