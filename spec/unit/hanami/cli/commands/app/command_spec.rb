# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Command do
  context "#call" do
    subject { cmd.new }

    let(:cmd) do
      Class.new(described_class) do
        def call(**)
        end
      end
    end

    it "invokes Hanami::Env.load" do
      expect(Hanami::Env).to receive(:load)

      subject.call
    end
  end
end
