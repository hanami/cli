# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Dev do
  subject { described_class.new(system_call: system_call) }
  let(:system_call) { instance_double(Hanami::CLI::InteractiveSystemCall) }

  context "#call" do
    it "invokes external command to start Procfile based session" do
      expect(system_call).to receive(:call).with "bin/dev"

      subject.call
    end
  end
end
