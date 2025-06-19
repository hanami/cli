# frozen_string_literal: true

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

  let(:dump_command) { instance_spy(Hanami::CLI::Commands::App::DB::Structure::Dump) }
  let(:dump) { false }

  before do
    allow(command).to receive(:exit)
    allow(Hanami::CLI::Commands::App::DB::Structure::Dump).to receive(:new) { dump_command }
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
    command.run_command(Hanami::CLI::Commands::App::DB::Migrate, dump: dump)
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

      write "config/db/migrate/20240602221330_add_published_to_posts.rb", <<~RUBY
        ROM::SQL.migration do
          change do
            alter_table :posts do
              add_column :published, :boolean, null: false, default: false
            end
          end
        end
      RUBY

      write "slices/main/config/db/migrate/20240602201330_create_invoices.rb", <<~RUBY
        ROM::SQL.migration do
          change do
            create_table :invoices do
              primary_key :id
              column :amount, :decimal, null: false
            end
          end
        end
      RUBY

      write "slices/main/config/db/migrate/20240602211330_add_status_to_invoices.rb", <<~RUBY
        ROM::SQL.migration do
          change do
            alter_table :invoices do
              add_column :status, :text, null: false, default: 'pending'
            end
          end
        end
      RUBY
    end

    Dir.chdir(@dir)
  end

  def before_prepare
    write "config/db/.keep", ""
    write "app/relations/.keep", ""
    write "slices/main/config/db/.keep", ""
    write "slices/main/relations/.keep", ""
  end

  before do
    ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
    ENV["MAIN__DATABASE_URL"] = "sqlite://db/main.sqlite3"

    db_create
    db_migrate
  end

  context "with general migrations existing" do
    # TODO: add tests for other databases
    describe "sqlite" do
      before do
        ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
        ENV["MAIN__DATABASE_URL"] = "sqlite://db/main.sqlite3"
        db_create
        db_migrate
      end

      it "rolls back all (app and slices) databases with no arguments" do
        expect(Hanami.app.root.join("db", "app.sqlite3").exist?).to be true
        columns = -> { Hanami.app["db.gateway"].connection.schema(:posts).map(&:first) }
        expect(columns.()).to eq [:id, :title, :body, :published]

        command.call

        expect(columns.()).to eq [:id, :title, :body]
        # expect(dump_command).to have_received(:call).with(hash_including(app: false, slice: nil))
        expect(output).to include "database db/app.sqlite3 rolled back"
      end

      it "rolls back app AND slices database with a specified number of steps" do
        columns = -> { Hanami.app["db.gateway"].connection.schema(:posts).map(&:first) }
        expect(columns.()).to eq [:id, :title, :body, :published]

        command.call(steps: "3")

        expect(Hanami.app["db.gateway"].connection.tables).not_to include :posts
        # expect(dump_command).to have_received(:call).with(hash_including(app: false, slice: nil))
        expect(output).to include "database db/app.sqlite3 rolled back"
        expect(output).to include "database db/main.sqlite3 rolled back"
      end

      it "rolls back app database only with --app flag" do
        columns = -> { Hanami.app["db.gateway"].connection.schema(:posts).map(&:first) }
        expect(columns.()).to eq [:id, :title, :body, :published]

        command.call(app: true)

        expect(columns.()).to eq [:id, :title, :body]
        # expect(dump_command).to have_received(:call).with(hash_including(app: true, slice: nil))
        expect(output).to include "database db/app.sqlite3 rolled back"
      end

      it "rolls back app database with a specified number of steps and --app flag" do
        columns = -> { Hanami.app["db.gateway"].connection.schema(:posts).map(&:first) }
        expect(columns.()).to eq [:id, :title, :body, :published]

        command.call(steps: "3", app: true)

        expect(Hanami.app["db.gateway"].connection.tables).not_to include :posts
        # expect(dump_command).to have_received(:call).with(hash_including(app: true, slice: nil))
        expect(output).to include "database db/app.sqlite3 rolled back"
      end

      it "rolls back slice database only with --slice flag" do
        columns = -> { Main::Slice["db.gateway"].connection.schema(:invoices).map(&:first) }
        expect(columns.()).to eq [:id, :amount, :status]

        command.call(slice: "main")

        expect(columns.()).to eq [:id, :amount]
        # expect(dump_command).to have_received(:call).with(hash_including(app: false, slice: "main"))
        expect(output).to include "database db/main.sqlite3 rolled back"
      end

      it "rolls back slice database with a specified number of steps and --slice flag" do
        columns = -> { Main::Slice["db.gateway"].connection.schema(:invoices).map(&:first) }
        expect(columns.()).to eq [:id, :amount, :status]

        command.call(steps: "2", slice: "main")

        expect(Main::Slice["db.gateway"].connection.tables).not_to include :invoices
        # expect(dump_command).to have_received(:call).with(hash_including(app: false, slice: "main"))
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
end
