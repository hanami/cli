# frozen_string_literal: true

require "shellwords"
require_relative "../command"
require_relative "../../../system_call"

module Hanami
  module CLI
    module Commands
      module App
        module Assets
          # @since 2.1.0
          # @api private
          class Command < App::Command
            def initialize(config: app.config.assets, system_call: SystemCall.new, **)
              super()
              @system_call = system_call
              @config = config
            end

            # @since 2.1.0
            # @api private
            def call(**)
              cmd, *args = cmd_with_args

              system_call.call(cmd, *args)
            end

            private

            # @since 2.1.0
            # @api private
            attr_reader :config

            # @since 2.1.0
            # @api private
            attr_reader :system_call

            # @since 2.1.0
            # @api private
            def cmd_with_args
              [config.package_manager_run_command, "assets"]
            end

            # @since 2.1.0
            # @api private
            def escape(str)
              Shellwords.shellescape(str)
            end
          end
        end
      end
    end
  end
end
