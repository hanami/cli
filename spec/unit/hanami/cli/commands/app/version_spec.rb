# frozen_string_literal: true

require "hanami/cli/commands/app/version"

RSpec.describe Hanami::CLI::Commands::App::Version do
  subject { described_class.new(out: stdout) }
  let(:stdout) { StringIO.new }

  it "prints current Hanami version to stdout" do
    subject.call

    stdout.rewind
    expect(stdout.read.chomp).to eq("v#{Hanami::VERSION}")
  end
end
