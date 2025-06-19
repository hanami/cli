# frozen_string_literal: true

require "pry"

RSpec.describe Hanami::CLI::Commands::App::DB::Rollback, :app_integration do
  subject(:command) {
    described_class.new(
      system_call: system_call,
      out: out
    )
  }

  let(:system_call) { Hanami::CLI::SystemCall.new }
  let(:out) { StringIO.new }
  def output = out.string

  before do
    allow(command).to receive(:exit)
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

  def db_migrate
    command.run_command(Hanami::CLI::Commands::App::DB::Migrate)
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

    Dir.chdir(@dir)
  end

  def before_prepare
    write "config/db/migrate/20250602201330_create_posts.rb", <<~RUBY
      ROM::SQL.migration do
        change do
          create_table :posts do
            primary_key :id
            column :title, :text, null: false
          end
        end
      end
    RUBY

    write "config/db/migrate/20250603211330_add_body_to_posts.rb", <<~RUBY
      ROM::SQL.migration do
        change do
          alter_table :posts do
            add_column :body, :text, null: false
          end
        end
      end
    RUBY

    write "config/db/migrate/20250604221330_add_published_to_posts.rb", <<~RUBY
      ROM::SQL.migration do
        change do
          alter_table :posts do
            add_column :published, :boolean, null: false, default: false
          end
        end
      end
    RUBY

    write "slices/main/config/db/migrate/20250605201330_create_invoices.rb", <<~RUBY
      ROM::SQL.migration do
        change do
          create_table :invoices do
            primary_key :id
            column :amount, :decimal, null: false
          end
        end
      end
    RUBY

    write "slices/main/config/db/migrate/20250606211330_add_status_to_invoices.rb", <<~RUBY
      ROM::SQL.migration do
        change do
          alter_table :invoices do
            add_column :status, :text, null: false, default: 'pending'
          end
        end
      end
    RUBY

    write "config/db/.keep", ""
    write "app/relations/.keep", ""
    write "slices/main/config/db/.keep", ""
    write "slices/main/relations/.keep", ""
  end

  # TODO: add tests for other databases
  describe "sqlite" do
    before :all do
      ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
      ENV["MAIN__DATABASE_URL"] = "sqlite://db/main.sqlite3"
    end

    before :each do
      db_create
      db_migrate
    end

    it "rolls back the most recent migration across all databases with no arguments" do
      columns = -> { Main::Slice["db.gateway"].connection.schema(:invoices).map(&:first) }
      expect(columns.()).to eq [:id, :amount, :status]

      command.call

      expect(columns.()).to eq [:id, :amount]
      expect(output).to include "database db/main.sqlite3 rolled back"
      expect(output).to_not include "database db/app.sqlite3 rolled back"
    end

    it "rolls back X most recent migrations across all databases with a specified number of steps" do
      columns = -> { Hanami.app["db.gateway"].connection.schema(:posts).map(&:first) }
      expect(columns.()).to eq [:id, :title, :body, :published]

      command.call(steps: "4")

      expect(columns.()).to eq [:id, :title]
      expect(output).to include "database db/app.sqlite3 rolled back"
      expect(output).to include "database db/main.sqlite3 rolled back"
    end

    it "rolls back app database only with --app flag" do
      columns = -> { Hanami.app["db.gateway"].connection.schema(:posts).map(&:first) }
      expect(columns.()).to eq [:id, :title, :body, :published]

      command.call(app: true)

      expect(columns.()).to eq [:id, :title, :body]
      expect(output).to include "database db/app.sqlite3 rolled back"
      expect(output).to_not include "database db/main.sqlite3 rolled back"
    end

    it "rolls back app database only with a specified number of steps and --app flag" do
      columns = -> { Hanami.app["db.gateway"].connection.schema(:posts).map(&:first) }
      expect(columns.()).to eq [:id, :title, :body, :published]

      command.call(steps: "3", app: true)

      expect(Hanami.app["db.gateway"].connection.tables).not_to include :posts
      expect(output).to include "database db/app.sqlite3 rolled back"
      expect(output).to_not include "database db/main.sqlite3 rolled back"
    end

    it "rolls back slice database only with --slice flag" do
      columns = -> { Main::Slice["db.gateway"].connection.schema(:invoices).map(&:first) }
      expect(columns.()).to eq [:id, :amount, :status]

      command.call(slice: "main")

      expect(columns.()).to eq [:id, :amount]
      expect(output).to include "database db/main.sqlite3 rolled back"
    end

    it "rolls back slice database with a specified number of steps and --slice flag" do
      columns = -> { Main::Slice["db.gateway"].connection.schema(:invoices).map(&:first) }
      expect(columns.()).to eq [:id, :amount, :status]

      command.call(steps: "2", slice: "main")

      expect(Main::Slice["db.gateway"].connection.tables).not_to include :invoices
      expect(output).to include "database db/main.sqlite3 rolled back"
    end

    it "handles case when there are no migrations to roll back" do
      command.call(steps: "3")
      out.truncate(0)

      command.call

      expect(output).to include "no migrations to rollback"
      expect(dump_command).not_to have_received(:call)
    end

    it "rollback everything when steps flag is bigger than the number of migrations" do
      command.call(steps: "42")

      command.call

      expect(output).to include "database db/main.sqlite3 rolled back"
    end

    it "does not dump the database structure when given --dump=false" do
      command.call(dump: false)

      expect(dump_command).not_to have_received(:call)
    end
  end
end
