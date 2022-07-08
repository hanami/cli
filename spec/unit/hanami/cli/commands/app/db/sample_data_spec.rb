# frozen_string_literal: true

require "hanami/cli/commands/app/db/sample_data"

RSpec.describe Hanami::CLI::Commands::App::DB::SampleData, :app, :command, :db do
  it "loads sample data file" do
    command.call

    expect(output).to include("sample data loaded from db/sample_data.rb")
  end

  it "warns if file is not found" do
    pending "no fixture ready for this scenario"

    command.call

    expect(output).to include("sample db/sample_data.rb not found")
  end
end
