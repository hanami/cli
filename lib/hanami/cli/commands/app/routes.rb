# frozen_string_literal: true

require "hanami"
require "hanami/router/inspector"

module Hanami
  module CLI
    module Commands
      module App
        # Inspect the application routes
        #
        # All the formatters available from `hanami-router` are available:
        #
        # ```
        # $ hanami routes --format=csv
        # ```
        #
        # Experimental: You can also use a custom formatter registered in the
        # application container. You can identify it by its key:
        #
        # ```
        # $ hanami routes --format=custom_routes_formatter
        # ```
        class Routes < Hanami::CLI::Command
          DEFAULT_FORMAT = "human_friendly"
          private_constant :DEFAULT_FORMAT

          VALID_FORMATS = [
            DEFAULT_FORMAT,
            "csv"
          ].freeze
          private_constant :VALID_FORMATS

          desc "Inspect application"

          option :format,
                 default: DEFAULT_FORMAT,
                 required: false,
                 desc: "Output format"

          # @api private
          def call(format: DEFAULT_FORMAT, slice: nil)
            require "hanami/prepare"
            inspector = Hanami::Router::Inspector.new(formatter: resolve_formatter(format))
            app.router(inspector: inspector)
            out.puts inspector.call
          end

          private

          def resolve_formatter(format)
            if VALID_FORMATS.include?(format)
              resolve_formatter_from_hanami_router(format)
            else
              resolve_formatter_from_app(format)
            end
          end

          def resolve_formatter_from_hanami_router(format)
            case format
            when "human_friendly"
              require "hanami/router/formatter/human_friendly"
              Hanami::Router::Formatter::HumanFriendly.new
            when "csv"
              require "hanami/router/formatter/csv"
              Hanami::Router::Formatter::CSV.new
            end
          end

          # Experimental
          def resolve_formatter_from_app(format)
            app[format]
          end

          def app
            Hanami.app
          end
        end
      end
    end
  end
end
