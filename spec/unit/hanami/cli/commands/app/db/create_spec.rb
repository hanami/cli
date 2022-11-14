# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::DB::Create, :app, :command do
  let(:database) do
    instance_double(Hanami::CLI::Commands::DB::Utils::Database, name: "test")
  end

  it "creates a database" do
    allow(command).to receive(:database).and_return(database)
    expect(database).to receive(:create_command).and_return(true)

    command.call

    expect(output).to include("database test created")
  end
end
