# frozen_string_literal: true

require "irb"

RSpec.describe Hanami::CLI::Commands::App::Console, :app do
  subject { described_class.new(fs: fs, out: out, err: err) }

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }

  before do
    irb_instance = double(IRB::Irb)
    allow(irb_instance).to receive(:run).and_return(nil)
    allow(IRB::Irb).to receive(:new).and_return(irb_instance)
  end

  context "when not passed any additional flags" do
    it "does not automatically boot the containers" do
      subject.call

      expect(app.booted?).to be_falsy
    end
  end

  context "when passing the --boot flag" do
    it "automatically boots the app container" do
      subject.call(boot: true)

      expect(app.booted?).to be_truthy
    end
  end
end
