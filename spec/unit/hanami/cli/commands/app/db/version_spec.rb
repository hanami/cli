# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Version, :app, :command, :db do
  it "outputs schema version" do
    expect(database).to receive(:applied_migrations).and_return(["312_create_users"])

    command.call

    expect(output).to include("current schema version is 312")
  end

  it "outputs not available when there's no info in the migrations table" do
    expect(database).to receive(:applied_migrations).and_return([])

    command.call

    expect(output).to include("current schema version is not available")
  end
end
