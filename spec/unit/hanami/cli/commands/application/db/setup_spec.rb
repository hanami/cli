# frozen_string_literal: true

require "hanami/cli/commands/application/db/setup"

RSpec.describe Hanami::CLI::Commands::Application::DB::Setup, :app, :command do
  let(:database) do
    instance_double(Hanami::CLI::Commands::DB::Utils::Database, name: "test")
  end

  it "sets up a database" do
    pending "No proper fixtures yet to make this pass"

    allow(command).to receive(:database).and_return(database)
    expect(database).to receive(:create_command).and_return(true)

    command.call

    expect(output).to include("database test created")
  end
end
