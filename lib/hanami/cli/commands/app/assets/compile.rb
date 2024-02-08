# frozen_string_literal: true

require_relative "command"

module Hanami
  module CLI
    module Commands
      module App
        module Assets
          # @since 2.1.0
          # @api private
          class Compile < Assets::Command
            desc "Compile assets for deployments"

            def initialize(config: app.config.assets, system_call: InteractiveSystemCall.new(exit_after: false), **opts)
              super(config: config, system_call: system_call, **opts)
            end

            private

            # @since 2.1.0
            # @api private
            def assets_command(slice)
              cmd = super

              if config.subresource_integrity.any?
                cmd << "--sri=#{escape(config.subresource_integrity.join(','))}"
              end

              cmd
            end
          end
        end
      end
    end
  end
end
