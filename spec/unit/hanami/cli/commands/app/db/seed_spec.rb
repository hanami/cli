# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Seed, :app, :command, :db do
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
