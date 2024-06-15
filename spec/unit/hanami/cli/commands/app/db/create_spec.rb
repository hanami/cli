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

    it "prints the errors if the create command fails and exits with non-zero status" do
      # It would be nice for hanami-cli to offer a cleaner way of providing non-zero exit statuses,
      # but this will do for now.
      allow(command).to receive :exit

      allow(system_call).to receive(:call).with("createdb bookshelf_development", anything)
        .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 1, out: "", err: "createdb-err")

      command.call

      expect(output).to include "createdb-err"
      expect(output).to include "failed to create database bookshelf_development"

      expect(command).to have_received(:exit).with 1
    end
  end

  context "multiple dbs across app and slices" do
    def before_prepare
      write "config/db/.keep", ""
      write "app/relations/.keep", ""
      write "slices/admin/config/db/.keep", ""
      write "slices/admin/relations/.keep", ""
      write "slices/main/config/db/.keep", ""
      write "slices/main/relations/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "postgres://localhost:5432/bookshelf_development"
      ENV["ADMIN__DATABASE_URL"] = "postgres://localhost:5432/bookshelf_admin_development"
      ENV["MAIN__DATABASE_URL"] = "postgres://anotherhost:2345/bookshelf_main_development"
    end

    it "creates each database" do
      command.call

      expect(system_call).to have_received(:call)
        .with(
          "createdb bookshelf_development",
          env: {
            "PGHOST" => "localhost",
            "PGPORT" => "5432"
          }
        )
        .once

      expect(system_call).to have_received(:call)
        .with(
          "createdb bookshelf_admin_development",
          env: {
            "PGHOST" => "localhost",
            "PGPORT" => "5432"
          }
        )
        .once

      expect(system_call).to have_received(:call)
        .with(
          "createdb bookshelf_main_development",
          env: {
            "PGHOST" => "anotherhost",
            "PGPORT" => "2345"
          }
        )
        .once

      expect(output).to include "database bookshelf_development created"
      expect(output).to include "database bookshelf_admin_development created"
      expect(output).to include "database bookshelf_main_development created"
    end

    it "does not create databases that already exist" do
      allow_database_to_exist("bookshelf_development")
      allow_database_to_exist("bookshelf_admin_development")

      command.call

      expect(system_call).to have_received(:call)
        .with(
          "createdb bookshelf_main_development",
          env: {
            "PGHOST" => "anotherhost",
            "PGPORT" => "2345"
          }
        )
        .once

      expect(system_call).not_to have_received(:call)
        .with("createdb bookshelf_development", anything)
      expect(system_call).not_to have_received(:call)
        .with("createdb bookshelf_admin_development", anything)

      expect(output).to include "database bookshelf_development created"
      expect(output).to include "database bookshelf_admin_development created"
      expect(output).to include "database bookshelf_main_development created"
    end

    it "prints errors for any create commands that fail and exits with non-zero status" do
      allow(command).to receive :exit

      allow(system_call).to receive(:call).with("createdb bookshelf_development", anything)
        .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 1, out: "", err: "createdb-err-1")

      allow(system_call).to receive(:call).with("createdb bookshelf_admin_development", anything)
        .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 1, out: "", err: "createdb-err-2")

      command.call

      expect(system_call).to have_received(:call)
        .with(
          "createdb bookshelf_main_development",
          env: {
            "PGHOST" => "anotherhost",
            "PGPORT" => "2345"
          }
        )
        .once

      expect(output).to include "failed to create database bookshelf_development"
      expect(output).to include "createdb-err-1"
      expect(output).to include "failed to create database bookshelf_admin_development"
      expect(output).to include "createdb-err-2"

      expect(output).to include "database bookshelf_main_development created"

      expect(command).to have_received(:exit).with(1).exactly(1).time
    end
  end
end
