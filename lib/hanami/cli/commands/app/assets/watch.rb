# frozen_string_literal: true

require_relative "command"
require_relative "../../../interactive_system_call"

module Hanami
  module CLI
    module Commands
      module App
        module Assets
          # @since 2.1.0
          # @api private
          class Watch < Assets::Command
            desc "Start assets watch mode"

            def initialize(config: app.config.assets, system_call: InteractiveSystemCall.new, **)
              super(config: config, system_call: system_call)
            end

            private

            # @since 2.1.0
            # @api private
            def cmd_with_args
              super + ["--", "--watch"]
            end
          end
        end
      end
    end
  end
end
