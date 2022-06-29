# frozen_string_literal: true

require "hanami/cli/commands/application/server"
require "open-uri"
require "puma"

RSpec.describe Hanami::CLI::Commands::Application::Server do
  subject { described_class.new }

  it "starts rack server in the given environment" do
    host = ENV.fetch("HANAMI_CLI_TEST_HOST", "0.0.0.0")
    port = ENV.fetch("HANAMI_CLI_TEST_PORT", "9292")
    begin
      pid = fork do
        $stdout.reopen "/dev/null", "a"
        $stderr.reopen "/dev/null", "a"
        subject.call(
          config: File.join(File.dirname(__FILE__), "../../../../../fixtures/test/config.ru"),
          host: host,
          port: port,
          env: "staging"
        )
      end

      response = open_uri("http://#{host}:#{port}/")

      expect(response).to eq("Hello, world! (staging)")
    ensure
      Process.kill(:KILL, pid)
    end
  end

  def open_uri(uri, attempts = 5)
    URI.open(uri).read # rubocop:disable Security/Open
  rescue Errno::ECONNREFUSED
    raise if attempts.zero?

    sleep 1
    open_uri(uri, attempts - 1)
  end
end
