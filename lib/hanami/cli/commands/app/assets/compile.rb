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

            SUCCESSFUL_EXIT_CODE = 0

            # @since 2.1.0
            # @api private
            def call(**)
              result = super
              if result.exit_code == SUCCESSFUL_EXIT_CODE
                puts result.out

                if result.err && result.err != ""
                  puts ""
                  puts result.err
                end
              else
                raise AssetsCompilationError.new(result.out, result.err)
              end
            end

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
