# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Rollback, :app, :command, :db do
  context "given no target is specified" do
    context "there a no previous migrations" do
      it "rolls back to one before the current migration" do
        expect(database).to receive(:applied_migrations).and_return([])
        expect(database).to_not receive(:run_migrations)

        command.call(dump: false)

        expect(output).to include("no migrations to rollback")
      end
    end

    context "there is one previous migration" do
      it "rolls back to the initial state" do
        expect(database).to receive(:applied_migrations).and_return(["312_create_users"])

        if RUBY_VERSION > "3.2"
          expect(database).to receive(:run_migrations).with({target: 311}).and_return(true)
        else
          expect(database).to receive(:run_migrations).with(target: 311).and_return(true)
        end

        command.call(dump: false)

        expect(output).to include("database test rolled back to initial state")
      end
    end

    context "there are multiple previous migrations" do
      it "rolls back to one before the current migration" do
        expect(database).to receive(:applied_migrations).and_return(
          %w[
            312_create_users
            313_create_books
          ]
        )

        if RUBY_VERSION > "3.2"
          expect(database).to receive(:run_migrations).with({target: 312}).and_return(true)
        else
          expect(database).to receive(:run_migrations).with(target: 312).and_return(true)
        end

        command.call(dump: false)

        expect(output).to include("database test rolled back to 312_create_users")
      end
    end
  end

  context "given a target is specified" do
    it "rolls back to specified migration" do
      expect(database).to receive(:applied_migrations).and_return(["312_create_users"])

      if RUBY_VERSION > "3.2"
        expect(database).to receive(:run_migrations).with({target: 312}).and_return(true)
      else
        expect(database).to receive(:run_migrations).with(target: 312).and_return(true)
      end

      command.call(target: "312", dump: false)

      expect(output).to include("database test rolled back to 312_create_users")
    end

    it "warns if target migration is not found" do
      expect(database).to receive(:applied_migrations).and_return([])
      expect(database).to_not receive(:run_migrations)

      command.call(target: "312", dump: false)

      expect(output).to include("migration file for target 312 was not found")
    end
  end
end
