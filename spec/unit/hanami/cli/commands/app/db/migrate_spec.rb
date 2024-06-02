# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Migrate, :app_integration do
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

      write "app/relations/posts.rb", <<~RUBY
        module TestApp
          module Relations
            class Posts < Hanami::DB::Relation
              schema :posts, infer: true
            end
          end
        end
      RUBY
    end

    before do
      ENV["DATABASE_URL"] = "sqlite::memory"
      # ENV["DATABASE_URL"] = "sqlite://#{File.join(@dir, "test.db")}"
    end

    it "runs the migrations" do
      command.call

      expect(output).to match /database.+migrated/

      expect(Hanami.app["relations.posts"].to_a).to eq []
    end
  end
end

# RSpec.describe Hanami::CLI::Commands::App::DB::Migrate, :app, :command, :db do
#   it "runs migrations" do
#     expect(database).to receive(:run_migrations)

#     command.call

#     expect(output).to include("database test migrated")
#   end

#   it "runs migrations against a specific target" do
#     if RUBY_VERSION > "3.2"
#       expect(database).to receive(:run_migrations).with({target: 312})
#     else
#       expect(database).to receive(:run_migrations).with(target: 312)
#     end

#     command.call(target: "312")

#     expect(output).to include("database test migrated")
#   end

#   it "doesn't do anything with no migration files" do
#     pending "need a way to easily set up a test app with no migrations"

#     command.call

#     expect(output).to include("no migrations files found")
#   end
# end
