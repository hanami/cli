# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Drop, :app, :command, :db do
  it "drops a database" do
    expect(database).to receive(:drop_command).and_return(true)

    command.call

    expect(output).to include("database test dropped")
  end
end
