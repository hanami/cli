# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Assets::Watch, :app do
  subject { described_class.new(system_call: interactive_system_call) }
  let(:interactive_system_call) { proc { |**| } }

  context "#call" do
    it "invokes hanami-assets executable" do
      env = {"ESBUILD_ENTRY_POINTS" => "", "ESBUILD_OUTDIR" => File.join(Dir.pwd, "public", "assets")}
      expect(interactive_system_call).to receive(:call).with("npm", "exec", "hanami-assets", "--", "--watch", env: hash_including(env))

      subject.call
    end
  end
end
