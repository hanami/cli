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

            # @since 2.1.0
            # @api private
            def cmd_with_args
              result = super

              if config.subresource_integrity.any?
                result << "--"
                result << "--sri=#{escape(config.subresource_integrity.join(','))}"
              end

              result
            end
          end
        end
      end
    end
  end
end
