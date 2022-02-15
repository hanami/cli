# frozen_string_literal: true

require "rack"
require_relative "../application"
require_relative "../../server"

module Hanami
  module CLI
    module Commands
      module Application
        # Launch Hanami web server.
        #
        # It's intended to be used only on development. For production, you
        # should use the rack handler command directly (i.e. `bundle exec puma
        # -C config/puma.rb`).
        #
        # The server is just a thin wrapper on top of Rack::Server. The options that it
        # accepts fall into two different categories:
        #
        # - When not explicitly set, port and host are not passed to the rack
        # server instance. This way, they can be configured through the
        # configured rack handler (e.g., the puma configuration file).
        #
        # - All others are always given by the Hanami command.
        #
        # Run `bundle exec hanami server -h` to see all the supported options.
        class Server < Command
          desc "Start Hanami server"

          option :host, default: nil, required: false, desc: "The host address to bind to (falls back to the rack handler)"
          option :port, default: nil, required: false, desc: "The port to run the server on (falls back to the rack handler)"
          option :config, default: 'config.ru', required: false, desc: "Rack configuration file"
          option :debug, default: false, required: false, desc: "Turn on/off debug output", type: :boolean
          option :warn, default: false, required: false, desc: "Turn on/off warnings", type: :boolean

          private attr_reader :server

          def initialize(server: Hanami::CLI::Server.new)
            @server = server
          end

          # @api private
          def call(...)
            server.call(...)
          end
        end
      end
    end
  end
end
