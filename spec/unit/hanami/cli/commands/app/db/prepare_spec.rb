# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Prepare, :app_integration do
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

  describe "postgres", :postgres do
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

      write "config/db/seeds.rb", <<~RUBY
        app = Hanami.app

        app["relations.posts"].changeset(:create, title: "First post").commit
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

      write "slices/main/config/db/seeds.rb", <<~RUBY
        slice = Main::Slice

        slice["relations.comments"].changeset(:create, body: "First comment").commit
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
      ENV["DATABASE_URL"] = "#{POSTGRES_BASE_URL}_app"
      ENV["MAIN__DATABASE_URL"] = "#{POSTGRES_BASE_URL}_main"
    end

    context "from scratch, with structure dump and seeds" do
      before do
        command.run_command(Hanami::CLI::Commands::App::DB::Create)
        command.run_command(Hanami::CLI::Commands::App::DB::Migrate) # Dumps the structure

        # `db migrate` establishes a connection to the database, which will prevent it from being
        # dropped. To allow the drop, disconnect from the database by stopping the :db provider
        # (which requires starting it first, a prerequesite for it to be stopped).
        Hanami.app.start :db and Hanami.app.stop :db
        Main::Slice.start :db and Main::Slice.stop :db
        command.run_command(Hanami::CLI::Commands::App::DB::Drop)

        out.truncate(0)
      end

      it "creates the database, loads the structure, migrates the database, and loads the seeds" do
        expect(Hanami.app.root.join("config", "db", "structure.sql").exist?).to be true
        expect(Main::Slice.root.join("config", "db", "structure.sql").exist?).to be true

        # Add migrations not included in structure dump
        write "config/db/migrate/20240603201330_create_app_extras.rb", <<~RUBY
          ROM::SQL.migration do
            change do
              create_table :app_extras do
                primary_key :id
              end
            end
          end
        RUBY
        write "slices/main/config/db/migrate/20240604201330_create_main_extras.rb", <<~RUBY
          ROM::SQL.migration do
            change do
              create_table :main_extras do
                primary_key :id
              end
            end
          end
        RUBY

        command.call

        expect(Hanami.app["relations.posts"].to_a).to eq [{id: 1, title: "First post"}]
        expect(Main::Slice["relations.comments"].to_a).to eq [{id: 1, body: "First comment"}]

        # App dump
        dump = File.read(Hanami.app.root.join("config", "db", "structure.sql"))
        expect(dump).to include("CREATE TABLE public.posts")
        expect(dump).to include("CREATE TABLE public.app_extras")
        expect(dump).to include(<<~SQL)
          SET search_path TO "$user", public;

          INSERT INTO schema_migrations (filename) VALUES
          ('20240602201330_create_posts.rb'),
          ('20240603201330_create_app_extras.rb');
        SQL

        # Slice dump
        dump = File.read(Main::Slice.root.join("config", "db", "structure.sql"))
        expect(dump).to include("CREATE TABLE public.comments")
        expect(dump).to include("CREATE TABLE public.main_extras")
        expect(dump).to include(<<~SQL)
          SET search_path TO "$user", public;

          INSERT INTO schema_migrations (filename) VALUES
          ('20240602201330_create_comments.rb'),
          ('20240604201330_create_main_extras.rb');
        SQL

        expect(output).to include_in_order(
          "database hanami_cli_test_app created",
          "database hanami_cli_test_app migrated",
          "hanami_cli_test_app structure dumped to config/db/structure.sql",
          "seed data loaded from config/db/seeds.rb",
          "database hanami_cli_test_main created",
          "database hanami_cli_test_main migrated",
          "hanami_cli_test_main structure dumped to slices/main/config/db/structure.sql",
          "seed data loaded from slices/main/config/db/seeds.rb"
        )
      end
    end

    it "prepares the app db when given --app" do
      command.call(app: true)

      expect(Hanami.app["relations.posts"].to_a).to eq [{id: 1, title: "First post"}]
      expect { Main::Slice["relations.comments"].to_a }.to raise_error Sequel::DatabaseError

      dump = File.read(Hanami.app.root.join("config", "db", "structure.sql"))
      expect(dump).to include("CREATE TABLE public.posts")
      expect(Main::Slice.root.join("config", "db", "structure.sql").exist?).to be false

      expect(output).to include_in_order(
        "database hanami_cli_test_app created",
        "database hanami_cli_test_app migrated",
        "hanami_cli_test_app structure dumped to config/db/structure.sql",
        "seed data loaded from config/db/seeds.rb",
      )
      expect(output).not_to include "hanami_cli_test_main"
    end

    it "prepares a slice db when given --slice" do
      command.call(slice: "main")

      expect(Main::Slice["relations.comments"].to_a).to eq [{id: 1, body: "First comment"}]
      expect { Hanami.app["relations.posts"].to_a }.to raise_error Sequel::DatabaseError

      dump = File.read(Main::Slice.root.join("config", "db", "structure.sql"))
      expect(dump).to include("CREATE TABLE public.comments")
      expect(Hanami.app.root.join("config", "db", "structure.sql").exist?).to be false

      expect(output).to include_in_order(
        "database hanami_cli_test_main created",
        "database hanami_cli_test_main migrated",
        "hanami_cli_test_main structure dumped to slices/main/config/db/structure.sql",
        "seed data loaded from slices/main/config/db/seeds.rb"
      )
      expect(output).not_to include "hanami_cli_test_app"
    end

    context "from scratch, no structure dump" do
      before do
        command.run_command(Hanami::CLI::Commands::App::DB::Create, app: true)
        command.run_command(Hanami::CLI::Commands::App::DB::Migrate, app: true, dump: false)

        # `db migrate` establishes a connection to the database, which will prevent it from being
        # dropped. To allow the drop, disconnect from the database by stopping the :db provider
        # (which requires starting it first, a prerequesite for it to be stopped).
        Hanami.app.start :db and Hanami.app.stop :db
        command.run_command(Hanami::CLI::Commands::App::DB::Drop)

        out.truncate(0)
      end

      it "creates the database, migrates the database, and loads the seeds" do
        expect(Hanami.app.root.join("config", "db", "structure.sql").exist?).to be false

        command.call(app: true)

        expect(Hanami.app["relations.posts"].to_a).to eq [{id: 1, title: "First post"}]

        dump = File.read(Hanami.app.root.join("config", "db", "structure.sql"))
        expect(dump).to include("CREATE TABLE public.posts")
        expect(dump).to include(<<~SQL)
          SET search_path TO "$user", public;

          INSERT INTO schema_migrations (filename) VALUES
          ('20240602201330_create_posts.rb');
        SQL

        expect(output).to include_in_order(
          "database hanami_cli_test_app created",
          "database hanami_cli_test_app migrated",
          "hanami_cli_test_app structure dumped to config/db/structure.sql",
          "seed data loaded from config/db/seeds.rb",
        )
      end
    end

    context "database already exists" do
      before do
        command.run_command(Hanami::CLI::Commands::App::DB::Create)
      end

      it "migrates the database and loads the seeds" do
        command.call(app: true)

        expect(Hanami.app["relations.posts"].to_a).to eq [{id: 1, title: "First post"}]

        dump = File.read(Hanami.app.root.join("config", "db", "structure.sql"))
        expect(dump).to include("CREATE TABLE public.posts")
        expect(dump).to include(<<~SQL)
          SET search_path TO "$user", public;

          INSERT INTO schema_migrations (filename) VALUES
          ('20240602201330_create_posts.rb');
        SQL

        expect(output).to include_in_order(
          "database hanami_cli_test_app created", # TODO: it would be good not to include this
          "database hanami_cli_test_app migrated",
          "hanami_cli_test_app structure dumped to config/db/structure.sql",
          "seed data loaded from config/db/seeds.rb",
        )
      end
    end

    context "no seeds" do
      def before_prepare
        super()
        FileUtils.rm_f("config/db/seeds.rb")
      end

      it "creates and migrates the database" do
        command.call(app: true)

        expect(Hanami.app["relations.posts"].to_a).to eq [] # no seeds

        dump = File.read(Hanami.app.root.join("config", "db", "structure.sql"))
        expect(dump).to include("CREATE TABLE public.posts")
        expect(dump).to include(<<~SQL)
          SET search_path TO "$user", public;

          INSERT INTO schema_migrations (filename) VALUES
          ('20240602201330_create_posts.rb');
        SQL

        expect(output).to include_in_order(
          "database hanami_cli_test_app created", # TODO: it would be good not to include this
          "database hanami_cli_test_app migrated",
          "hanami_cli_test_app structure dumped to config/db/structure.sql"
        )
        expect(output).not_to include "seed data loaded from config/db/seeds.rb"
      end
    end

    it "prints errors for any prepares that fail and exits with a non-zero status" do
      # Fail to create the app db
      allow(system_call).to receive(:call).and_call_original
      allow(system_call)
        .to receive(:call)
        .with(a_string_matching(/createdb.+_app/), anything)
        .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 2, out: "", err: "app-db-err")

      command.call

      expect(Main::Slice["relations.comments"].to_a).to eq [{id: 1, body: "First comment"}]
      expect { Hanami.app["relations.posts"].to_a }.to raise_error Sequel::DatabaseError

      dump = File.read(Main::Slice.root.join("config", "db", "structure.sql"))
      expect(dump).to include("CREATE TABLE public.comments")
      expect(Hanami.app.root.join("config", "db", "structure.sql").exist?).to be false

      expect(output).to include_in_order(
        "failed to create database hanami_cli_test_app",
        "app-db-err",
        "database hanami_cli_test_main created",
        "database hanami_cli_test_main migrated",
        "hanami_cli_test_main structure dumped to slices/main/config/db/structure.sql",
        "seed data loaded from slices/main/config/db/seeds.rb"
      )

      expect(command).to have_received(:exit).with 2
    end
  end
end
