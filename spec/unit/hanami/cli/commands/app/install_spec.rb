# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Install do
  subject { described_class.new(system_call: system_call, out: stdout) }
  let(:stdout) { StringIO.new }
  let(:system_call) { instance_double(Hanami::CLI::SystemCall, call: successful_system_call_result) }

  describe "#call" do
    it "installs third-party plugins" do
      subject.call

      stdout.rewind
      expect(stdout.read.chomp).to eq("")
    end

    context "when hanami-assets is bundled" do
      before do
        allow(Hanami).to receive(:bundled?)
        allow(Hanami).to receive(:bundled?).with("hanami-assets").and_return(true)

        allow(system_call).to receive(:call).with("npm", ["init", "-y"])
        allow(system_call).to receive(:call).with("npm", %w[install hanami-assets])
      end

      it "installs JavaScript deps" do
        subject.call

        stdout.rewind
        expect(stdout.read.chomp).to eq("")
      end
    end
  end
end
