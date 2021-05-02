# frozen_string_literal: true

require "hanami/cli/commands/monolith/console"
require "pry"

RSpec.describe Hanami::CLI::Commands::Monolith::Console, :app do
  subject(:command) { described_class.new(out: stdout) }

  let(:stdout) { StringIO.new }

  it "starts app's console" do
    expect(Pry).to receive(:start).with(instance_of(Hanami::Console::Context))

    subject.call
  end
end
