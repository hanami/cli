# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Structure::Load, :app_integration do
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
  end

  def db_structure_dump
    command.run_command(Hanami::CLI::Commands::App::DB::Create)
    command.run_command(Hanami::CLI::Commands::App::DB::Migrate)

    # `db migrate` establishes a connection to the database, which will prevent it from being
    # dropped. To allow the drop, disconnect from the database by stopping the :db provider
    # (which requires starting it first, a prerequesite for it to be stopped).
    Hanami.app.start :db and Hanami.app.stop :db
    Main::Slice.start :db and Main::Slice.stop :db

    command.run_command(Hanami::CLI::Commands::App::DB::Drop)
    command.run_command(Hanami::CLI::Commands::App::DB::Create)

    out.truncate(0)
  end

  def table_exists?(slice, table_name)
    slice["db.gateway"].connection
      .fetch("SELECT COUNT(*) FROM information_schema.tables WHERE table_name = '#{table_name}'")
      .to_a.first.fetch(:count) == 1
  end

  describe "postgres", :postgres do
    before do
      ENV["DATABASE_URL"] = "#{POSTGRES_BASE_URL}_app"
      ENV["MAIN__DATABASE_URL"] = "#{POSTGRES_BASE_URL}_main"
      db_structure_dump
    end

    it "loads the structure for each db" do
      expect { command.call }
        .to change { table_exists?(Hanami.app, "posts") }
        .and change { table_exists?(Main::Slice, "comments") }
        .to true

      expect(output).to include_in_order(
        "hanami_cli_test_app structure loaded from config/db/structure.sql",
        "hanami_cli_test_main structure loaded from slices/main/config/db/structure.sql"
      )
    end

    it "loads the structure for the app db when given --app" do
      expect { command.call(app: true) }
        .to change { table_exists?(Hanami.app, "posts") }
        .to true

      expect(table_exists?(Main::Slice, "comments")).to be false

      expect(output).to include "hanami_cli_test_app structure loaded from config/db/structure.sql"
      expect(output).not_to include "hanami_cli_test_main"
    end

    it "loads the structure for a slice db when given --slice" do
      expect { command.call(slice: "main") }
        .to change { table_exists?(Main::Slice, "comments") }
        .to true

      expect(table_exists?(Hanami.app, "posts")).to be false

      expect(output).to include "hanami_cli_test_main structure loaded from slices/main/config/db/structure.sql"
      expect(output).not_to include "hanami_cli_test_app"
    end

    it "prints errors for any dumps that fail and exits with non-zero status" do
      # Fail to load the app db
      allow(system_call).to receive(:call).and_call_original
      allow(system_call)
        .to receive(:call)
        .with(a_string_including("#{POSTGRES_BASE_DB_NAME}_app"), anything)
        .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 2, out: "", err: "app-load-err")

      command.call

      expect(table_exists?(Hanami.app, "posts")).to be false
      expect(table_exists?(Main::Slice, "comments")).to be true

      expect(output).to include %("#{POSTGRES_BASE_DB_NAME}_app structure loaded from config/db/structure.sql" FAILED)
      expect(output).to include "#{POSTGRES_BASE_DB_NAME}_main structure loaded from slices/main/config/db/structure.sql"

      expect(command).to have_received(:exit).with 2
    end
  end
end
