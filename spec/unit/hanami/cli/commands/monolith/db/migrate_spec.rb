# frozen_string_literal: true

require "hanami/cli/commands/monolith/db/migrate"

RSpec.describe Hanami::CLI::Commands::Monolith::DB::Migrate, :app, :command, :db do
  it "runs migrations" do
    expect(database).to receive(:run_migrations)

    command.call

    expect(output).to include("database test migrated")
  end

  it "runs migrations against a specific target" do
    expect(database).to receive(:run_migrations).with(target: 312)

    command.call(target: "312")

    expect(output).to include("database test migrated")
  end

  it "doesn't do anything with no migration files" do
    pending "need a way to easily set up a test app with no migrations"

    command.call

    expect(output).to include("no migrations files found")
  end
end
