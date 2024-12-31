# frozen_string_literal: true

module Hanami
  module CLI
    # @since 2.0.0
    # @api private
    class Server
      # @since 2.0.0
      # @api private
      attr_reader :rack_server

      # @since 2.0.0
      # @api private
      RACK_FALLBACK_OPTIONS = {
        host: :Host,
        port: :Port
      }.freeze

      # @since 2.0.0
      # @api private
      OVERRIDING_OPTIONS = {
        config: :config,
        debug: :debug,
        warn: :warn
      }.freeze

      # @since 2.0.0
      # @api private
      def initialize(rack_server: Rackup::Server)
        @rack_server = rack_server
      end

      # @since 2.0.0
      # @api private
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
