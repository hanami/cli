# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Assets::Compile, :app do
  subject { described_class.new(system_call: system_call) }
  let(:system_call) { proc { |**| } }

  context "#call" do
    it "invokes hanami-assets executable" do
      expect(system_call).to receive(:call).with(Hanami.app.config.assets.exe_path)

      subject.call
    end
  end
end
