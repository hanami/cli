# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Assets::Watch do
  subject { described_class.new(interactive_system_call: interactive_system_call) }
  let(:interactive_system_call) { proc { |**| } }
  let(:executable) { File.join("node_modules", "hanami-assets", "dist", "hanami-assets.js") }

  context "#call" do
    it "invokes hanami-assets executable" do
      expect(interactive_system_call).to receive(:call).with(executable, "--watch")

      subject.call
    end
  end
end
