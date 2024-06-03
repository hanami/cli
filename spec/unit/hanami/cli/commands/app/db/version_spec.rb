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

  def migrate
    command.run_command(Hanami::CLI::Commands::App::DB::Migrate)
    out.truncate(0)
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

    it "outputs the version" do
      migrate

      command.call

      expect(output).to include "app.db current schema version is 20240602211330_add_body_to_posts"
    end
  end

  context "multiple dbs" do
    # WIP
  end

  # it "outputs not available when there's no info in the migrations table" do
  #   expect(database).to receive(:applied_migrations).and_return([])

  #   command.call

  #   expect(output).to include("current schema version is not available")
  # end
end
