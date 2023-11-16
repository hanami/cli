# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Assets::Compile, :app do
  subject { described_class.new(system_call: system_call) }
  let(:system_call) { proc { |**| } }

  context "#call" do
    it "invokes hanami-assets executable" do
      expect(system_call).to receive(:call).with("npm run --silent", "assets") { Hanami::CLI::SystemCall::Result.new(exit_code: 0, out: "", err: "") }

      subject.call
    end

    it "writes stdout and stderr to stdout on success" do
      expect(system_call).to receive(:call).with("npm run --silent", "assets") { Hanami::CLI::SystemCall::Result.new(exit_code: 0, out: "This is out", err: "This is err") }
      expect($stdout).to receive(:puts).with("This is out")
      expect($stdout).to receive(:puts).with("")
      expect($stdout).to receive(:puts).with("This is err")

      subject.call
    end

    it "writes only stdout when stderr is empty on success" do
      expect(system_call).to receive(:call).with("npm run --silent", "assets") { Hanami::CLI::SystemCall::Result.new(exit_code: 0, out: "This is out", err: "") }
      expect($stdout).to receive(:puts).with("This is out")

      subject.call
    end

    it "raises exception on non-zero exit code" do
      expect(system_call).to receive(:call).with("npm run --silent", "assets") { Hanami::CLI::SystemCall::Result.new(exit_code: 1, out: "This is out", err: "This is err") }
      expect { subject.call }.to raise_error(Hanami::CLI::AssetsCompilationError, "This is out\n\nErrors on assets compilation:\n\nThis is err")
    end
  end
end
