# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Structure::Dump, :app_integration do
  subject(:command) {
    described_class.new(
      system_call: system_call,
      out: out
    )
  }

  let(:system_call) { instance_spy(Hanami::CLI::SystemCall) }

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

  context "postgres" do
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
        ENV["DATABASE_URL"] = "postgres://localhost:5432/bookshelf_development"
      end

      it "works?" do
        command.call

        expect(system_call).to have_received(:call)
          .with(
            "pg_dump --schema-only --no-owner bookshelf_development > #{@dir.realpath.join("config", "db", "structure.sql")}",
            env: {
              "PGHOST" => "localhost",
              "PGPORT" => "5432"
            }
          )
      end
    end
  end
end
