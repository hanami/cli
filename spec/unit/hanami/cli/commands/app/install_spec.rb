# frozen_string_literal: true

require "hanami/cli/commands/app/install"

RSpec.describe Hanami::CLI::Commands::App::Install do
  subject { described_class.new(out: stdout) }
  let(:stdout) { StringIO.new }

  it "prints current Hanami version to stdout" do
    subject.call

    stdout.rewind
    expect(stdout.read.chomp).to eq("")
  end
end
