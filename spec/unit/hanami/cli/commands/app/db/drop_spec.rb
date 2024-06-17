# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Drop, :app_integration do
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

  def allow_any_database_to_exist
    list_command_re = %r{psql -t -A -c '\\list (?<db_name>.+)'}

    allow(system_call)
      .to receive(:call)
      .with(a_string_matching(list_command_re), anything) { |*args|
        db_name = list_command_re.match(args.first)[:db_name]

        Hanami::CLI::SystemCall::Result.new(
          exit_code: 0,
          out: "#{db_name}|postgres|UTF8|libc|en_US.UTF-8|en_US.UTF-8|||",
          err: ""
        )
      }
  end

  def allow_database_not_to_exist(name)
    allow(system_call)
      .to receive(:call)
      .with("psql -t -A -c '\\list #{name}'", anything)
      .and_return(Hanami::CLI::SystemCall::Result.new(exit_code: 0, out: "\n", err: ""))
  end

  before do
    allow_any_database_to_exist
  end

  context "single db in app" do
    def before_prepare
      write "config/db/.keep", ""
      write "app/relations/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "postgres://localhost:5432/bookshelf_development"
    end

    it "drops the database" do
      command.call

      expect(system_call).to have_received(:call)
        .with(
          "dropdb bookshelf_development",
          env: {
            "PGHOST" => "localhost",
            "PGPORT" => "5432"
          }
        )

      expect(output).to include "database bookshelf_development dropped"
    end

    it "does not drop the database if it doesn't exist" do
      allow_database_not_to_exist("bookshelf_development")

      command.call

      expect(system_call).not_to have_received(:call)
        .with("dropdb bookshelf_development", anything)

      expect(output).to include "database bookshelf_development dropped"
    end

    it "prints the errors if the drop command fails and exits with non-zero status" do
      # It would be nice for hanami-cli to offer a cleaner way of providing non-zero exit statuses,
      # but this will do for now.
      allow(command).to receive :exit

      allow(system_call).to receive(:call).with("dropdb bookshelf_development", anything)
        .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 1, out: "", err: "dropdb-err")

      command.call

      expect(output).to include "dropdb-err"
      expect(output).to include "failed to drop database bookshelf_development"

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

    it "drops each database" do
      command.call

      expect(system_call).to have_received(:call)
        .with(
          "dropdb bookshelf_development",
          env: {
            "PGHOST" => "localhost",
            "PGPORT" => "5432"
          }
        )
        .once

      expect(system_call).to have_received(:call)
        .with(
          "dropdb bookshelf_admin_development",
          env: {
            "PGHOST" => "localhost",
            "PGPORT" => "5432"
          }
        )
        .once

      expect(system_call).to have_received(:call)
        .with(
          "dropdb bookshelf_main_development",
          env: {
            "PGHOST" => "anotherhost",
            "PGPORT" => "2345"
          }
        )
        .once

      expect(output).to include "database bookshelf_development dropped"
      expect(output).to include "database bookshelf_admin_development dropped"
      expect(output).to include "database bookshelf_main_development dropped"
    end

    it "does not drop databases that do not exist" do
      allow_database_not_to_exist("bookshelf_development")
      allow_database_not_to_exist("bookshelf_admin_development")

      command.call

      expect(system_call).to have_received(:call)
        .with(
          "dropdb bookshelf_main_development",
          env: {
            "PGHOST" => "anotherhost",
            "PGPORT" => "2345"
          }
        )
        .once

      expect(system_call).not_to have_received(:call)
        .with("dropdb bookshelf_development", anything)
      expect(system_call).not_to have_received(:call)
        .with("dropdb bookshelf_admin_development", anything)

      expect(output).to include "database bookshelf_development dropped"
      expect(output).to include "database bookshelf_admin_development dropped"
      expect(output).to include "database bookshelf_main_development dropped"
    end

    it "prints errors for any drop commands that fail and exits with non-zero status" do
      allow(command).to receive :exit

      allow(system_call).to receive(:call).with("dropdb bookshelf_development", anything)
        .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 1, out: "", err: "dropdb-err-1")

      allow(system_call).to receive(:call).with("dropdb bookshelf_admin_development", anything)
        .and_return Hanami::CLI::SystemCall::Result.new(exit_code: 1, out: "", err: "dropdb-err-2")

      command.call

      expect(system_call).to have_received(:call)
        .with(
          "dropdb bookshelf_main_development",
          env: {
            "PGHOST" => "anotherhost",
            "PGPORT" => "2345"
          }
        )
        .once

      expect(output).to include "failed to drop database bookshelf_development"
      expect(output).to include "dropdb-err-1"
      expect(output).to include "failed to drop database bookshelf_admin_development"
      expect(output).to include "dropdb-err-2"

      expect(output).to include "database bookshelf_main_development dropped"

      expect(command).to have_received(:exit).with(1).exactly(1).time
    end
  end
end
