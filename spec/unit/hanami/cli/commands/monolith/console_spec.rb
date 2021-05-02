# frozen_string_literal: true

require "hanami/cli/commands/monolith/console"

require "pry"
require "irb"

RSpec.describe Hanami::CLI::Commands::Monolith::Console, :app do
  subject(:command) { described_class.new(out: stdout) }

  let(:stdout) { StringIO.new }

  context "irb" do
    xit "starts app's console" do
      expect(IRB).to receive(:start)

      subject.call
    end

    xit "starts app's console with a forced env via option" do
      expect(IRB).to receive(:start)

      subject.call(env: "production")

      expect(Hanami.env).to be(:production)
    end
  end

  context "pry" do
    it "starts app's console" do
      expect(Pry).to receive(:start).with(instance_of(Hanami::Console::Context))

      subject.call(repl: "pry")
    end

    it "starts app's console with a forced env via option" do
      expect(Pry).to receive(:start).with(instance_of(Hanami::Console::Context))

      subject.call(env: "production", repl: "pry")

      expect(Hanami.env).to be(:production)
    end
  end
end
