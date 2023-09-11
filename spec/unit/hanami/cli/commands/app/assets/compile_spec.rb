# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Assets::Compile do
  subject { described_class.new(system_call: system_call) }
  let(:system_call) { proc { |**| } }
  let(:executable) { File.join("node_modules", "hanami-assets", "dist", "hanami-assets.js") }

  context "#call" do
    it "invokes hanami-assets executable" do
      expect(system_call).to receive(:call).with(executable)

      subject.call
    end
  end
end
