# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Create, :app_integration do
  subject(:command) {
    described_class.new(
      system_call: system_call,
      out: out
    )
  }

  let(:system_call) {
    instance_spy(
      Hanami::CLI::SystemCall,
      call: Hanami::CLI::SystemCall::Result.new(exit_code: 0, out: "", err: "")
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

  def allow_database_not_to_exist
    allow(system_call)
      .to receive(:call)
      .with(a_string_starting_with("psql -t -A -c '\\list"))
      .and_return(Hanami::CLI::SystemCall::Result.new(exit_code: 0, out: "\n", err: ""))
  end

  def allow_database_to_exist(name)
    allow(system_call)
      .to receive(:call)
      .with("psql -t -A -c '\\list #{name}'", anything)
      .and_return(Hanami::CLI::SystemCall::Result.new(
        exit_code: 0,
        out: "#{name}|postgres|UTF8|libc|en_US.UTF-8|en_US.UTF-8|||",
        err: ""
      ))
  end

  before do
    allow_database_not_to_exist
  end

  context "single db in app" do
    def before_prepare
      write "config/db/.keep", ""
      write "app/relations/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "postgres://localhost:5432/bookshelf_development"
    end

    it "creates the database" do
      command.call

      expect(system_call).to have_received(:call)
        .with(
          "createdb bookshelf_development",
          env: {
            "PGHOST" => "localhost",
            "PGPORT" => "5432"
          }
        )

      expect(output).to include "database bookshelf_development created"
    end

    it "does not create the database if it already exists" do
      allow_database_to_exist("bookshelf_development")

      command.call

      expect(system_call).not_to have_received(:call)
        .with("createdb bookshelf_development", anything)

      expect(output).to include "database bookshelf_development created"
    end
  end
end
