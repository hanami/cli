RSpec.describe Hanami::CLI::Server do
  describe "#call" do
    subject { described_class.new(rack_server: rack_server) }

    let(:rack_server) do
      Class.new do
        attr_reader :options

        def start(options)
          @options = options
        end
      end.new
    end

    it "delegates host as Host" do
      subject.call(host: "127.0.0.3")

      expect(subject.rack_server.options[:Host]).to eq("127.0.0.3")
    end

    it "delegates port as Port" do
      subject.call(port: 2000)

      expect(subject.rack_server.options[:Port]).to be(2000)
    end

    it "delegates config as config" do
      subject.call(config: "config.ru")

      expect(subject.rack_server.options[:config]).to eq("config.ru")
    end

    it "delegates debug as debug" do
      subject.call(debug: true)

      expect(subject.rack_server.options[:debug]).to be(true)
    end

    it "delegates warn as warn" do
      subject.call(warn: true)

      expect(subject.rack_server.options[:warn]).to be(true)
    end
  end
end
