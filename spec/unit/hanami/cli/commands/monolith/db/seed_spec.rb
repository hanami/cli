# frozen_string_literal: true

require "hanami/cli/commands/monolith/db/seed"

RSpec.describe Hanami::CLI::Commands::Monolith::DB::Seed, :app, :command, :db do
  it "loads sample data file" do
    command.call

    expect(output).to include("seed data loaded from db/seeds.rb")
  end

  it "warns if file is not found" do
    pending "no fixture ready for this scenario"

    command.call

    expect(output).to include("db/seeds.rb not found")
  end
end
