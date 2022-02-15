module Hanami
  module CLI
    # @api private
    class Server
      attr_reader :rack_server

      RACK_FALLBACK_OPTIONS = {
        host: :Host,
        port: :Port
      }.freeze

      OVERRIDING_OPTIONS = {
        config: :config,
        debug: :debug,
        warn: :warn
      }.freeze

      def initialize(rack_server: Rack::Server)
        @rack_server = rack_server
      end

      def call(**options)
        rack_server.start(Hash[
          extract_rack_fallback_options(options) + extract_overriding_options(options)
        ])
      end

      private

      def extract_rack_fallback_options(options)
        RACK_FALLBACK_OPTIONS.filter_map do |(name, rack_name)|
          options[name] && [rack_name, options[name]]
        end
      end

      def extract_overriding_options(options)
        OVERRIDING_OPTIONS.map do |(name, rack_name)|
          [rack_name, options[name]]
        end
      end
    end
  end
end
