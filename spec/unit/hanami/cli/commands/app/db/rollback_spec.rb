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

  let(:dump_command) { instance_spy(Hanami::CLI::Commands::App::DB::Structure::Dump) }

  before do
    allow(Hanami::CLI::Commands::App::DB::Structure::Dump).to receive(:new) { dump_command }
  end

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
    command.run_command(Hanami::CLI::Commands::App::DB::Create, dump: false)
    out.truncate(0)
  end

  def db_migrate
    command.run_command(Hanami::CLI::Commands::App::DB::Migrate, dump: false)
    out.truncate(0)
  end

  # TODO: add tests for other databases
  describe "sqlite" do
    before :all do
      ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
      ENV["MAIN__DATABASE_URL"] = "sqlite://db/main.sqlite3"
    end

    context "with one database" do
      it "rolls back the most recent migration found" do
        with_directory(@dir = make_tmp_directory) do
          write "config/app.rb", <<~RUBY
            module TestApp
              class App < Hanami::App
                config.logger.stream = File::NULL
              end
            end
          RUBY

          require "hanami/setup"
          before_prepare_single
          require "hanami/prepare"
        end

        Dir.chdir(@dir)

        db_create
        db_migrate

        columns = -> { Hanami.app["db.gateway"].connection.schema(:posts).map(&:first) }
        expect(columns.()).to eq [:id, :title, :body, :published]

        command.call

        expect(columns.()).to eq [:id, :title, :body]
        expect(output).to include "database db/app.sqlite3 rolled back to 20250603211330_add_body_to_posts in"
        expect(dump_command).to have_received(:call).with(hash_including(app: false)).once
      end
    end

    context "with multiple databases" do
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
          before_prepare_multiple if respond_to?(:before_prepare_multiple)
          require "hanami/prepare"
        end

        Dir.chdir(@dir)

        db_create
        db_migrate
      end

      context "with invalid args combinations" do
        context "when app and slice are specified" do
          it "does not allow ambiguity, asks for details" do
            pending "not implemented"
          end
        end

        context "when gateway that does not exist in the context is specified" do
          it "informs about invalid gateway" do
            pending "not implemented"
          end
        end
      end

      context "with no args" do
        it "does not allow ambiguity, asks for details" do
          pending "not implemented"
        end
      end

      context "with correct arguments" do
        it "rolls back X most recent migrations across the chosen database" do
          columns_slice = -> { Main::Slice["db.gateway"].connection.schema(:invoices).map(&:first) }
          expect(columns_slice.()).to eq [:id, :amount, :status]

          command.call(steps: "2", slice: "main")

          expect(Main::Slice["db.gateway"].connection.tables).not_to include :invoices
          expect(output).to include "database db/main.sqlite3 rolled back"
          expect(dump_command).to have_received(:call).with(hash_including(app: false, slice: "main"))
        end

        it "rolls back app database only with --app flag" do
          columns = -> { Hanami.app["db.gateway"].connection.schema(:posts).map(&:first) }
          expect(columns.()).to eq [:id, :title, :body, :published]

          command.call(app: true)

          expect(columns.()).to eq [:id, :title, :body]
          expect(output).to include "database db/app.sqlite3 rolled back"
          expect(output).to_not include "database db/main.sqlite3 rolled back"
          expect(dump_command).to have_received(:call).with(hash_including(app: true, slice: nil))
        end

        it "rolls back app database only with a specified number of steps and --app flag" do
          columns = -> { Hanami.app["db.gateway"].connection.schema(:posts).map(&:first) }
          expect(columns.()).to eq [:id, :title, :body, :published]

          command.call(steps: "3", app: true)

          expect(Hanami.app["db.gateway"].connection.tables).not_to include :posts
          expect(output).to include "database db/app.sqlite3 rolled back"
          expect(output).to_not include "database db/main.sqlite3 rolled back"
          expect(dump_command).to have_received(:call).with(hash_including(app: true, slice: nil))
        end

        it "rolls back slice database only with --slice flag" do
          columns = -> { Main::Slice["db.gateway"].connection.schema(:invoices).map(&:first) }
          expect(columns.()).to eq [:id, :amount, :status]

          command.call(slice: "main")

          expect(columns.()).to eq [:id, :amount]
          expect(output).to include "database db/main.sqlite3 rolled back"
          expect(dump_command).to have_received(:call).with(hash_including(app: false, slice: "main"))
        end

        # duplicated now
        xit "rolls back slice database with a specified number of steps and --slice flag" do
          columns = -> { Main::Slice["db.gateway"].connection.schema(:invoices).map(&:first) }
          expect(columns.()).to eq [:id, :amount, :status]

          command.call(steps: "2", slice: "main")

          expect(Main::Slice["db.gateway"].connection.tables).not_to include :invoices
          expect(output).to include "database db/main.sqlite3 rolled back"
          expect(dump_command).to have_received(:call).with(hash_including(app: false, slice: "main"))
        end

        it "handles case when there are no migrations to roll back" do
          command.call(steps: "5")
          out.truncate(0)

          command.call

          expect(output).to include "no migrations to rollback"
        end

        it "handles case when input timestamp target is invalid" do
          out.truncate(0)

          command.call(target: "20250101101110")

          expect(output).to include "==> migration file for target 20250101101110 was not found"
        end

        it "handles case when input timestamp target is valid" do
          out.truncate(0)

          command.call(target: "20250602201330")

          expect(output).to include "database db/app.sqlite3 rolled back to 20250602201330_create_posts"
        end

        it "rollback everything on selected database when steps flag is bigger than the number of migrations" do
          command.call(steps: "42", slice: "main")

          command.call

          expect(output).to include "database db/main.sqlite3 rolled back"
          expect(dump_command).to have_received(:call).exactly(2).times
        end

        it "does not dump the database structure when given --dump=false" do
          command.call(dump: false)

          expect(dump_command).not_to have_received(:call)
        end
      end
    end

    context "app with multiple gateways" do
      before do
        ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
        ENV["DATABASE_URL__EXTRA"] = "sqlite://db/app_extra.sqlite3"
        ENV["DATABASE_URL__SUPER"] = "sqlite://db/app_super.sqlite3"

        with_directory(@dir = make_tmp_directory) do
          write "config/app.rb", <<~RUBY
            module TestApp
              class App < Hanami::App
                config.logger.stream = File::NULL
              end
            end
          RUBY

          require "hanami/setup"
          before_prepare_gateways if respond_to?(:before_prepare_gateways)
          require "hanami/prepare"
        end

        Dir.chdir(@dir)

        db_create
        db_migrate
      end

      context "with no arguments" do
        it "asks for more detailed prompt" do
          command.call

          expect(output).to include "Please specify the gateway to rollback"
        end
      end

      it "rollbacks specific gateway and dumps the structure for a single app gateway with --app and --gateway" do
        expect(Hanami.app["db.gateways.default"].connection.tables).to include :posts
        expect(Hanami.app["db.gateways.extra"].connection.tables).to include :users
        expect(Hanami.app["db.gateways.super"].connection.tables).to include :comments

        command.call(app: true, gateway: "extra")

        expect(Hanami.app["db.gateways.super"].connection.tables).to include :comments
        expect(Hanami.app["db.gateways.extra"].connection.tables).to_not include :users
        expect(dump_command).to have_received(:call).with(hash_including(app: true, slice: nil, gateway: "extra"))
        expect(dump_command).to have_received(:call).once

        expect(output).to include "database db/app_extra.sqlite3 rolled back"
        expect(output).not_to include "db/app.sqlite3"
        expect(output).not_to include "db/app_super.sqlite3"
      end
    end
  end

  def before_prepare_single
    prepare_posts
    write "config/db/.keep", ""
    write "app/relations/.keep", ""
  end

  def before_prepare_multiple
    prepare_posts

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

  def before_prepare_gateways
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

    write "config/db/extra_migrate/20250603201330_create_users.rb", <<~RUBY
      ROM::SQL.migration do
        change do
          create_table :users do
            primary_key :id
            column :name, :text, null: false
          end
        end
      end
    RUBY

    write "config/db/super_migrate/20250604201330_create_comments.rb", <<~RUBY
      ROM::SQL.migration do
        change do
          create_table :comments do
            primary_key :id
            column :content, :text, null: false
          end
        end
      end
    RUBY
  end

  def prepare_posts
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
  end
end
