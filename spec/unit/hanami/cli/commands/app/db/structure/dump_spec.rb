# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Structure::Dump, :app_integration, :postgres do
  subject(:command) {
    described_class.new(
      system_call: system_call,
      out: out
    )
  }

  let(:system_call) { Hanami::CLI::SystemCall.new }

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
    # Prevent the command from exiting the spec run in the case of unexpected system call failures
    allow(command).to receive(:exit)
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

      write "app/relations/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "#{POSTGRES_BASE_URL}_app"

      command.run_command(Hanami::CLI::Commands::App::DB::Create)
      command.run_command(Hanami::CLI::Commands::App::DB::Migrate, dump: false)
      out.truncate(0)
    end

    it "dumps the structure for the app db, including schema_migrations" do
      command.call

      dump = File.read(Hanami.app.root.join("config", "db", "structure.sql"))
      expect(dump).to include("CREATE TABLE public.posts")
      expect(dump).to include(<<~SQL)
        SET search_path TO "$user", public;

        INSERT INTO schema_migrations (filename) VALUES
        ('20240602201330_create_posts.rb');
      SQL

      expect(output).to include "hanami_cli_test_app structure dumped to config/db/structure.sql"
    end
  end

  context "multiple dbs across app and slices" do
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
      write "app/relations/.keep", ""

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
      write "slices/main/relations/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "#{POSTGRES_BASE_URL}_app"
      ENV["MAIN__DATABASE_URL"] = "#{POSTGRES_BASE_URL}_main"

      command.run_command(Hanami::CLI::Commands::App::DB::Create)
      command.run_command(Hanami::CLI::Commands::App::DB::Migrate, dump: false)
      out.truncate(0)
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

      expect(output).to include "hanami_cli_test_app structure dumped to config/db/structure.sql"
      expect(output).to include "hanami_cli_test_main structure dumped to slices/main/config/db/structure.sql"
    end

    it "dumps the structure for the app db when given --app" do
      command.call(app: true)

      expect(Hanami.app.root.join("config", "db", "structure.sql").exist?).to be true
      expect(Main::Slice.root.join("config", "db", "structure.sql").exist?).to be false

      expect(output).to include "hanami_cli_test_app structure dumped to config/db/structure.sql"
      expect(output).not_to include "hanami_cli_test_main structure dumped to slices/main/config/db/structure.sql"
    end

    it "dumps the structure for a slice db when given --slice" do
      command.call(slice: "main")

      expect(Main::Slice.root.join("config", "db", "structure.sql").exist?).to be true
      expect(Hanami.app.root.join("config", "db", "structure.sql").exist?).to be false

      expect(output).to include "hanami_cli_test_main structure dumped to slices/main/config/db/structure.sql"
      expect(output).not_to include "hanami_cli_test_app structure dumped to config/db/structure.sql"
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

      expect(output).to include %("hanami_cli_test_app structure dumped to config/db/structure.sql" FAILED)
      expect(output).to include "hanami_cli_test_main structure dumped to slices/main/config/db/structure.sql"

      expect(command).to have_received(:exit).with 2
    end
  end
end
