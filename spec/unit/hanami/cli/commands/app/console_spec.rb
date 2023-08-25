# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Console do
  subject { described_class.new }

  context "#call" do
    context "with engine provided" do
      let(:pry) do
        instance_double(Hanami::CLI::Repl::Pry, name: "pry")
      end

      it "invokes pry" do
        allow(Hanami::CLI::Repl::Pry).to receive(:new).and_return(pry)

        expect(pry).to receive(:start)
        subject.call(engine: 'pry')
      end
    end

    context "with default engine" do
      let(:irb) do
        instance_double(Hanami::CLI::Repl::Irb, name: "irb")
      end

      it "invokes irb" do
        allow(Hanami::CLI::Repl::Irb).to receive(:new).and_return(irb)

        expect(irb).to receive(:start)

        subject.call
      end
    end
  end
end
