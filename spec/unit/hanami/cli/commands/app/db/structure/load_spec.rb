# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Structure::Load, :app_integration do
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

  context "single db in app" do
    def before_prepare
      write "app/relations/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "postgres://localhost:5432/bookshelf_development"
    end

    it "dumps the structure for the app db" do
      command.call

      expect(system_call).to have_received(:call)
        .with(
          "psql --set ON_ERROR_STOP=1 --quiet --no-psqlrc --output /dev/null --file #{@dir.realpath.join("config", "db", "structure.sql")} bookshelf_development",
          env: {
            "PGHOST" => "localhost",
            "PGPORT" => "5432"
          }
        )

      expect(output).to include "bookshelf_development structure loaded from config/db/structure.sql"
    end
  end

  context "multiple dbs across app and slices" do
    def before_prepare
      write "app/relations/.keep", ""
      write "slices/admin/relations/.keep", ""
      write "slices/main/relations/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "postgres://localhost:5432/bookshelf_development"
      ENV["ADMIN__DATABASE_URL"] = "postgres://localhost:5432/bookshelf_admin_development"
      ENV["MAIN__DATABASE_URL"] = "postgres://anotherhost:2345/bookshelf_main_development"
    end

    it "dumps the structure for each db" do
      command.call

      expect(system_call).to have_received(:call)
        .with(
          "psql --set ON_ERROR_STOP=1 --quiet --no-psqlrc --output /dev/null --file #{@dir.realpath.join("config", "db", "structure.sql")} bookshelf_development",
          env: {
            "PGHOST" => "localhost",
            "PGPORT" => "5432"
          }
        )
        .once

      expect(system_call).to have_received(:call)
        .with(
          "psql --set ON_ERROR_STOP=1 --quiet --no-psqlrc --output /dev/null --file #{@dir.realpath.join("slices", "admin", "config", "db", "structure.sql")} bookshelf_admin_development",
          env: {
            "PGHOST" => "localhost",
            "PGPORT" => "5432"
          }
        )
        .once

      expect(system_call).to have_received(:call)
        .with(
          "psql --set ON_ERROR_STOP=1 --quiet --no-psqlrc --output /dev/null --file #{@dir.realpath.join("slices", "main", "config", "db", "structure.sql")} bookshelf_main_development",
          env: {
            "PGHOST" => "anotherhost",
            "PGPORT" => "2345"
          }
        )
        .once

      expect(output).to include "bookshelf_development structure loaded from config/db/structure.sql"
      expect(output).to include "bookshelf_admin_development structure loaded from slices/admin/config/db/structure.sql"
      expect(output).to include "bookshelf_main_development structure loaded from slices/main/config/db/structure.sql"
    end

    it "dumps the structure for the app db when given --app" do
      command.call(app: true)

      expect(system_call).to have_received(:call).exactly(1).time

      expect(system_call).to have_received(:call)
        .with(
          "psql --set ON_ERROR_STOP=1 --quiet --no-psqlrc --output /dev/null --file #{@dir.realpath.join("config", "db", "structure.sql")} bookshelf_development",
          env: {
            "PGHOST" => "localhost",
            "PGPORT" => "5432"
          }
        )

      expect(output).to include "bookshelf_development structure loaded from config/db/structure.sql"
    end

    it "dumps the structure for a slice db when given --slice" do
      command.call(slice: "admin")

      expect(system_call).to have_received(:call).exactly(1).time

      expect(system_call).to have_received(:call)
        .with(
          "psql --set ON_ERROR_STOP=1 --quiet --no-psqlrc --output /dev/null --file #{@dir.realpath.join("slices", "admin", "config", "db", "structure.sql")} bookshelf_admin_development",
          env: {
            "PGHOST" => "localhost",
            "PGPORT" => "5432"
          }
        )

      expect(output).to include "bookshelf_admin_development structure loaded from slices/admin/config/db/structure.sql"
    end
  end

  context "load command fails" do
    def before_prepare
      write "config/db/.keep", ""
      write "app/relations/.keep", ""
    end

    before do
      ENV["DATABASE_URL"] = "postgres://localhost:5432/bookshelf_development"
    end

    before do
      allow(system_call).to receive(:call).and_return Hanami::CLI::SystemCall::Result.new(
        exit_code: 2,
        out: "",
        err: "some-psql-error"
      )
    end

    it "prints the error" do
      command.call

      expect(output).to include "some-psql-error"
      expect(output).to include %(!!! => "bookshelf_development structure loaded from config/db/structure.sql" FAILED)
    end
  end
end
