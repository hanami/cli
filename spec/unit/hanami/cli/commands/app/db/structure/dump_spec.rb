# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Structure::Dump, :app_integration, :postgres do
  subject(:command) {
    described_class.new(system_call: system_call, out: out)
  }

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

  def db_migrate
    command.run_command(Hanami::CLI::Commands::App::DB::Create)
    command.run_command(Hanami::CLI::Commands::App::DB::Migrate, dump: false)
    out.truncate(0)
  end

  describe "sqlite" do
    before do
      ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
      ENV["MAIN__DATABASE_URL"] = "sqlite://db/main.sqlite3"
      db_migrate
    end

    it "dumps the structure for each db, including schema_migrations" do
      command.call

      dump = File.read(Hanami.app.root.join("config", "db", "structure.sql"))
      expect(dump).to include("CREATE TABLE `posts`")
      expect(dump).to include(<<~SQL)
        INSERT INTO schema_migrations (filename) VALUES
        ('20240602201330_create_posts.rb');
      SQL

      dump = File.read(Main::Slice.root.join("config", "db", "structure.sql"))
      expect(dump).to include("CREATE TABLE `comments`")
      expect(dump).to include(<<~SQL)
        INSERT INTO schema_migrations (filename) VALUES
        ('20240602201330_create_comments.rb');
      SQL

      expect(output).to include_in_order(
        "db/app.sqlite3 structure dumped to config/db/structure.sql",
        "db/main.sqlite3 structure dumped to slices/main/config/db/structure.sql",
      )
    end

    it "dumps the structure for the app db when given --app" do
      command.call(app: true)

      expect(Hanami.app.root.join("config", "db", "structure.sql").exist?).to be true
      expect(Main::Slice.root.join("config", "db", "structure.sql").exist?).to be false

      expect(output).to include "db/app.sqlite3 structure dumped to config/db/structure.sql"
      expect(output).not_to include "db/main.sqlite3"
    end

    it "dumps the structure for a slice db when given --slice" do
      command.call(slice: "main")

      expect(Main::Slice.root.join("config", "db", "structure.sql").exist?).to be true
      expect(Hanami.app.root.join("config", "db", "structure.sql").exist?).to be false

      expect(output).to include "db/main.sqlite3 structure dumped to slices/main/config/db/structure.sql"
      expect(output).not_to include "db/app.sqlite3"
    end

    it "prints errors for any dumps that fail and exits with non-zero status" do
      # Fail to dump the app db
      allow(system_call).to receive(:call).and_call_original
      allow(system_call)
        .to receive(:call)
        .with(a_string_including("db/app.sqlite3"))
        .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 2, out: "", err: "dump-err")

      command.call

      expect(Main::Slice.root.join("config", "db", "structure.sql").exist?).to be true
      expect(Hanami.app.root.join("config", "db", "structure.sql").exist?).to be false

      expect(output).to include %("db/app.sqlite3 structure dumped to config/db/structure.sql" FAILED)
      expect(output).to include "db/main.sqlite3 structure dumped to slices/main/config/db/structure.sql"

      expect(command).to have_received(:exit).with 2
    end
  end

  describe "postgres", :postgres do
    before do
      ENV["DATABASE_URL"] = "#{POSTGRES_BASE_URL}_app"
      ENV["MAIN__DATABASE_URL"] = "#{POSTGRES_BASE_URL}_main"
      db_migrate
    end

    it "dumps the structure for each db, including schema_migrations" do
      command.call

      dump = File.read(Hanami.app.root.join("config", "db", "structure.sql"))
      expect(dump).to include("CREATE TABLE public.posts")
      expect(dump).to include(<<~SQL)
        SET search_path TO "$user", public;

        INSERT INTO schema_migrations (filename) VALUES
        ('20240602201330_create_posts.rb');
      SQL

      dump = File.read(Main::Slice.root.join("config", "db", "structure.sql"))
      expect(dump).to include("CREATE TABLE public.comments")
      expect(dump).to include(<<~SQL)
        SET search_path TO "$user", public;

        INSERT INTO schema_migrations (filename) VALUES
        ('20240602201330_create_comments.rb');
      SQL

      expect(output).to include_in_order(
        "#{POSTGRES_BASE_DB_NAME}_app structure dumped to config/db/structure.sql",
        "#{POSTGRES_BASE_DB_NAME}_main structure dumped to slices/main/config/db/structure.sql"
      )
    end

    it "dumps the structure for the app db when given --app" do
      command.call(app: true)

      expect(Hanami.app.root.join("config", "db", "structure.sql").exist?).to be true
      expect(Main::Slice.root.join("config", "db", "structure.sql").exist?).to be false

      expect(output).to include "#{POSTGRES_BASE_DB_NAME}_app structure dumped to config/db/structure.sql"
      expect(output).not_to include "#{POSTGRES_BASE_DB_NAME}_main"
    end

    it "dumps the structure for a slice db when given --slice" do
      command.call(slice: "main")

      expect(Main::Slice.root.join("config", "db", "structure.sql").exist?).to be true
      expect(Hanami.app.root.join("config", "db", "structure.sql").exist?).to be false

      expect(output).to include "#{POSTGRES_BASE_DB_NAME}_main structure dumped to slices/main/config/db/structure.sql"
      expect(output).not_to include "#{POSTGRES_BASE_DB_NAME}_app"
    end

    it "prints errors for any dumps that fail and exits with non-zero status" do
      # Fail to dump the app db
      allow(system_call).to receive(:call).and_call_original
      allow(system_call)
        .to receive(:call)
        .with(a_string_including("app"), anything)
        .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 2, out: "", err: "dump-err")

      command.call

      expect(Main::Slice.root.join("config", "db", "structure.sql").exist?).to be true
      expect(Hanami.app.root.join("config", "db", "structure.sql").exist?).to be false

      expect(output).to include %("#{POSTGRES_BASE_DB_NAME}_app structure dumped to config/db/structure.sql" FAILED)
      expect(output).to include "#{POSTGRES_BASE_DB_NAME}_main structure dumped to slices/main/config/db/structure.sql"

      expect(command).to have_received(:exit).with 2
    end
  end
end
