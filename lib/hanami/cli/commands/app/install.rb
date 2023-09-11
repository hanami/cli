# frozen_string_literal: true

require_relative "../../system_call"

module Hanami
  module CLI
    module Commands
      module App
        # The `install` command exists to provide third parties a hook for their own installation
        # behaviour to be run as part of `hanami new`.
        #
        # Third parties should register their install commands like so:
        #
        # ```
        # if Hanami::CLI.within_hanami_app?
        #   Hanami::CLI.after "install", MyHanamiGem::CLI::Commands::Install
        # end
        # ````
        #
        # @since 2.0.0
        # @api private
        class Install < Command
          # @since 2.1.0
          # @api private
          DEFAULT_EDGE = false
          private_constant :DEFAULT_EDGE

          # @since 2.1.0
          # @api private
          desc "Install Hanami third-party plugins"

          # @since 2.1.0
          # @api private
          option :edge, type: :boolean, desc: "Install edge deps", default: DEFAULT_EDGE

          # @since 2.1.0
          # @api private
          def initialize(system_call: SystemCall.new, **)
            @system_call = system_call
            super()
          end

          # @since 2.0.0
          # @api private
          def call(edge: DEFAULT_EDGE, **)
            install_hanami_assets!(edge: edge)
          end

          private

          # @since 2.1.0
          # @api private
          attr_reader :system_call

          def install_hanami_assets!(edge:)
            return unless Hanami.bundled?("hanami-assets")

            system_call.call("npm", ["init", "-y"])

            if edge
              system_call.call("npm", %w[install https://github.com/hanami/assets-js])
            else
              system_call.call("npm", %w[install hanami-assets])
            end
          end
        end
      end
    end
  end
end
