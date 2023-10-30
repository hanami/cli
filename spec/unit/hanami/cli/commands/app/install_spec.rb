# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Install do
  subject { described_class.new(out: stdout) }
  let(:stdout) { StringIO.new }

  describe "#call" do
    it "installs third-party plugins" do
      subject.call

      stdout.rewind
      expect(stdout.read.chomp).to eq("")
    end
  end
end
