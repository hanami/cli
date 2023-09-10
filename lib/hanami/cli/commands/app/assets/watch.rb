# frozen_string_literal: true

require_relative "../../../interactive_system_call"

module Hanami
  module CLI
    module Commands
      module App
        module Assets
          # @since 2.1.0
          # @api private
          class Watch < App::Command
            # @since 2.1.0
            # @api private
            WATCH_OPTION = "--watch"
            private_constant :WATCH_OPTION

            # @since 2.1.0
            # @api private
            #
            # TODO: Take `executable` from Hanami::Assets::Config
            def initialize(interactive_system_call: InteractiveSystemCall.new, executable: File.join("node_modules", "hanami-assets", "dist", "hanami-assets.js"), **)
              @interactive_system_call = interactive_system_call
              @executable = executable
              super()
            end

            # @since 2.1.0
            # @api private
            def call(**)
              interactive_system_call.call(executable, WATCH_OPTION)
            end

            private

            # @since 2.1.0
            # @api private
            attr_reader :interactive_system_call, :executable
          end
        end
      end
    end
  end
end
