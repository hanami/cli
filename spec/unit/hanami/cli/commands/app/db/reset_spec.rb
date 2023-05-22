RSpec.describe Hanami::CLI::Commands::App::DB::Reset, :app, :command, :db do
  it "drops, creates and migrates a database" do
    pending "ugh too much to mock"

    command.call

    expect(output).to include("database test dropped")
    expect(output).to include("database test created")
    expect(output).to include("database test migrated")
  end
end
