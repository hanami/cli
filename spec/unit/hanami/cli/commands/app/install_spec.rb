# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Install do
  subject { described_class.new(fs: fs, bundler: bundler, out: out) }

  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:bundler) { Hanami::CLI::Bundler.new(fs: fs) }
  let(:out) { StringIO.new }

  describe "#call" do
    it "installs third-party plugins" do
      expect(bundler).to receive(:install!)
        .exactly(1).time
        .and_return(true)

      subject.call

      out.rewind
      expect(out.read.chomp).to eq("")
    end
  end
end
