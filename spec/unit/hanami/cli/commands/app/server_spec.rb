# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Server do
  subject { described_class.new(server: server) }
  let(:server) { proc { |**| } }

  context "#call" do
    it "invokes server" do
      expect(server).to receive(:call)

      subject.call
    end

    context "it uses Hanami::Port#call port" do
      let(:port) { 7890 }

      it "invokes server" do
        allow(Hanami::Port).to receive(:[]).and_return(port)

        if RUBY_VERSION > "3.2"
          expect(server).to receive(:call).with({port: port})
        else
          expect(server).to receive(:call).with(port: port)
        end

        subject.call
      end
    end
  end
end
