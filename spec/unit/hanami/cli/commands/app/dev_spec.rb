# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Dev do
  subject { described_class.new(interactive_system_call: interactive_system_call) }
  let(:interactive_system_call) { proc { |**| } }
  let(:bin) { "bin/dev" }

  context "#call" do
    it "invokes external command to start Procfile based session" do
      expect(interactive_system_call).to receive(:call).with(bin)

      subject.call
    end
  end
end
