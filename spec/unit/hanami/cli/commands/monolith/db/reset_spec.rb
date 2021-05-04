# frozen_string_literal: true

require "hanami/cli/commands/monolith/db/reset"

RSpec.describe Hanami::CLI::Commands::Monolith::DB::Reset, :app, :command, :db do
  it "drops, creates and migrates a database" do
    pending "ugh too much to mock"

    command.call

    expect(output).to include("database test dropped")
    expect(output).to include("database test created")
    expect(output).to include("database test migrated")
  end
end
