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

            def call(**)
              slices = app.slices.with_nested + [app]
              pids = start_children(slices)

              %w[INT USR1 TERM].each do |sig|
                Signal.trap(sig) do
                  pids.each do |pid|
                    Process.kill(sig, pid)
                  end
                end
              end

              Process.waitall
            end

            private

            # @since 2.1.0
            # @api private
            def start_children(slices)
              slices.map do |slice|
                fork_child(slice)
              end
            end

            # @since 2.1.0
            # @api private
            def fork_child(slice)
              Process.fork do
                cmd, *args = cmd_with_args(slice)
                result = system_call.call(cmd, *args)

                # In ordinary usage, watch mode runs until it is interrupted by the user. We should
                # only get here if the watch command fails for some reason.
                if result.exit_code == 0
                  puts result.out

                  if result.err && result.err != ""
                    puts ""
                    puts result.err
                  end
                else
                  raise AssetsCompilationError.new(result.out, result.err)
                end
              rescue Interrupt => e
                # When this has been interrupted (by the Signal.trap handler in #call), catch the
                # interrupt and exit cleanly, without showing the default full backtrace.
              end
            end

            # @since 2.1.0
            # @api private
            def cmd_with_args(slice)
              result = [config.node_command, assets_config(slice).to_s, "--", "--watch"]

              if slice.eql?(slice.app)
                result << "--path=app"
                result << "--target=public/assets"
              else
                result << "--path=#{slice.root.relative_path_from(slice.app.root)}"
                result << "--target=public/assets/#{slice.slice_name}"
              end

              result
            end

            def assets_config(slice)
              config = slice.root.join("config", "assets.js")
              return config if config.exist?

              config = slice.app.root.join("config", "assets.js")
              return config if config.exist?

              # TODO: real error
              raise "no asset config found"
            end
          end
        end
      end
    end
  end
end
