RSpec.describe Hanami::CLI::Commands::App::DB::CreateMigration, :app, :command, :db do
  let(:migrator) do
    double(:migrator, generate_version: 312)
  end

  it "creates a migration file" do
    allow(database).to receive(:migrator).and_return(migrator)

    expect(migrator).to receive(:create_file).with("create_users", 312).and_return(true)

    command.call(name: "create_users")

    expect(output).to include("migration 312_create_users created")
  end
end
