# frozen_string_literal: true

require_relative "../../../system_call"

module Hanami
  module CLI
    module Commands
      module App
        module Assets
          # @since 2.1.0
          # @api private
          class Compile < App::Command
            desc "Compile assets for deployments"

            # @since 2.1.0
            # @api private
            #
            # TODO: Take `executable` from Hanami::Assets::Config
            def initialize(system_call: SystemCall.new, executable: nil, **)
              @system_call = system_call
              @executable = executable || app.config.assets.exe_path
              super()
            end

            # @since 2.1.0
            # @api private
            def call(**)
              system_call.call(executable)
            end

            private

            # @since 2.1.0
            # @api private
            attr_reader :system_call, :executable
          end
        end
      end
    end
  end
end
