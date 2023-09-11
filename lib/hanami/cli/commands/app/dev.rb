# frozen_string_literal: true

require_relative "../../interactive_system_call"

module Hanami
  module CLI
    module Commands
      module App
        # @since 2.1.0
        # @api private
        class Dev < App::Command
          # @since 2.1.0
          # @api private
          def initialize(interactive_system_call: InteractiveSystemCall.new, **)
            @interactive_system_call = interactive_system_call
            super()
          end

          # @since 2.1.0
          # @api private
          def call(**)
            bin, args = executable
            interactive_system_call.call(bin, *args)
          end

          private

          # @since 2.1.0
          # @api private
          attr_reader :interactive_system_call

          # @since 2.1.0
          # @api private
          def executable
            # TODO: support other implementations of Foreman
            # See: https://github.com/ddollar/foreman#ports
            ["foreman", ["start", "-f", "Procfile.dev"]]
          end
        end
      end
    end
  end
end
