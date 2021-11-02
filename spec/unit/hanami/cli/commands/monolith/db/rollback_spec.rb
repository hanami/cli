# frozen_string_literal: true

require "hanami/cli/commands/monolith/db/rollback"

RSpec.describe Hanami::CLI::Commands::Monolith::DB::Rollback, :app, :command, :db do
  it "rolls back to the second-to-last migration when target is not specified" do
    allow(database).to receive(:applied_migrations).and_return(["312_create_users", "325_create_groups"])
    allow(database).to receive(:run_migrations)

    command.call(dump: false)

    expect(database).to have_received(:run_migrations).with(target: 312)
  end

  it "rolls back to specified migration" do
    expect(database).to receive(:applied_migrations).and_return(["312_create_users"])
    expect(database).to receive(:run_migrations).with(target: 312)

    command.call(target: "312", dump: false)

    expect(output).to include("database test rolled back to 312_create_users")
    expect(output).not_to match(/failed/i)
  end

  it "warns if target migration is not found" do
    expect(database).to receive(:applied_migrations).and_return([])
    expect(database).to_not receive(:run_migrations)

    command.call(target: "312", dump: false)

    expect(output).to include("migration file for target 312 was not found")
  end
end
