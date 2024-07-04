# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Seed, :app_integration do
  subject(:command) {
    described_class.new(system_call: system_call, out: out)
  }

  let(:system_call) { Hanami::CLI::SystemCall.new }

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
            config.logger.stream = File::NULL
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

      write "slices/main/relations/comments.rb", <<~RUBY
        module Main
          module Relations
            class Comments < Hanami::DB::Relation
              schema :comments, infer: true
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
    command.run_command(Hanami::CLI::Commands::App::DB::Migrate, dump: false)
    out.truncate(0)
  end

  before do
    ENV["DATABASE_URL"] = "sqlite://db/app.sqlite3"
    ENV["MAIN__DATABASE_URL"] = "sqlite://db/main.sqlite3"

    db_migrate
  end

  context "seeds files present" do
    before do
      write "config/db/seeds.rb", <<~RUBY
        app = Hanami.app

        app["relations.posts"].changeset(:create, title: "First post").commit
      RUBY

      write "slices/main/config/db/seeds.rb", <<~RUBY
        slice = Main::Slice

        slice["relations.comments"].changeset(:create, body: "First comment").commit
      RUBY
    end

    it "loads the seeds" do
      command.call

      expect(Hanami.app["relations.posts"].to_a).to eq [{id: 1, title: "First post"}]
      expect(Main::Slice["relations.comments"].to_a).to eq [{id: 1, body: "First comment"}]

      expect(output).to include "seed data loaded from config/db/seeds.rb"
      expect(output).to include "seed data loaded from slices/main/config/db/seeds.rb"
    end

    it "loads the app seeds only when given --app" do
      command.call(app: true)

      expect(Hanami.app["relations.posts"].to_a).to eq [{id: 1, title: "First post"}]
      expect(Main::Slice["relations.comments"].to_a).to eq []

      expect(output).to include "seed data loaded from config/db/seeds.rb"
      expect(output).not_to include "seed data loaded from slices/main/config/db/seeds.rb"
    end

    it "loads a slice's seeds when given --slice" do
      command.call(slice: "main")

      expect(Hanami.app["relations.posts"].to_a).to eq []
      expect(Main::Slice["relations.comments"].to_a).to eq [{id: 1, body: "First comment"}]

      expect(output).to include "seed data loaded from slices/main/config/db/seeds.rb"
      expect(output).not_to include "seed data loaded from config/db/seeds.rb"
    end
  end

  context "some seeds files absent" do
    before do
      write "slices/main/config/db/seeds.rb", <<~RUBY
        slice = Main::Slice

        slice["relations.comments"].changeset(:create, body: "First comment").commit
      RUBY
    end

    it "loads the seeds that are present" do
      command.call

      expect(Hanami.app["relations.posts"].to_a).to eq []
      expect(Main::Slice["relations.comments"].to_a).to eq [{id: 1, body: "First comment"}]

      expect(output).not_to include "seed data loaded from config/db/seeds.rb"
      expect(output).to include "seed data loaded from slices/main/config/db/seeds.rb"
    end
  end

  context "all seeds files absent" do
    it "does not load any seeds" do
      command.call

      expect(Hanami.app["relations.posts"].to_a).to eq []
      expect(Main::Slice["relations.comments"].to_a).to eq []

      expect(output).to be_empty
    end
  end
end
