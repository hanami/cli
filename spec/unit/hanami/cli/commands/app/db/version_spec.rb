# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Version, :app_integration do
  subject(:command) { described_class.new(out: out) }

  let(:out) { StringIO.new }
  def output; out.string; end

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

      write "slices/admin/relations/.keep", ""

      require "hanami/setup"
      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end

    Dir.chdir(@dir)
  end

  def db_migrate
    command.run_command(Hanami::CLI::Commands::App::DB::Migrate, dump: false)
    out.truncate(0)
  end

  before do
    ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
    ENV["MAIN__DATABASE_URL"] = "sqlite://db/main.sqlite3"

    db_migrate
  end

  it "prints the versions for all databases" do
    command.call

    expect(output).to include_in_order(
      "db/app.sqlite3 current schema version is 20240602191330_create_categories",
      "db/main.sqlite3 current schema version is 20240602211330_create_comments"
    )
  end

  it "prints the version of the app db only when given --app" do
    command.call(app: true)

    expect(output).to include "db/app.sqlite3 current schema version is 20240602191330_create_categories"
    expect(output).not_to include "db/main.sqlite3"
  end

  it "prints the version of a slice when given --slice" do
    command.call(slice: "main")

    expect(output).to include "db/main.sqlite3 current schema version is 20240602211330_create_comments"
    expect(output).not_to include "db/app.db"
  end

  it "prints an error when given a slice without migrations" do
    command.call(slice: "admin")

    expect(output).to include %(Cannot find version for slice "admin")
    expect(output).not_to include "current schema version"
  end
end
