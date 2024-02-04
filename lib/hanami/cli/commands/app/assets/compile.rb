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

            def initialize(config: app.config.assets, system_call: InteractiveSystemCall.new(exit_after: false), **)
              super(config: config, system_call: system_call)
            end

            def call(**)
              slices = app.slices.with_nested + [app]
              pids = slices.map { |slice| fork_child(slice) if slice_assets?(slice) }

              Signal.trap("INT") do
                pids.each do |pid|
                  Process.kill(sig, pid)
                end
              end

              Process.waitall
            end

            private

            def fork_child(slice)
              Process.fork do
                cmd, *args = cmd_with_args(slice)
                system_call.call(cmd, *args, out_prefix: "[#{slice.slice_name}] ")
              rescue Interrupt => e
                # When this has been interrupted (by the Signal.trap handler in #call), catch the
                # interrupt and exit cleanly, without showing the default full backtrace.
              end
            end

            # @since 2.1.0
            # @api private
            def cmd_with_args(slice)
              result = [config.node_command, assets_config(slice).to_s, "--"]

              if slice.eql?(slice.app)
                result << "--path=app"
                result << "--target=public/assets"
              else
                result << "--path=#{slice.root.relative_path_from(slice.app.root)}"
                result << "--target=public/assets/#{slice.slice_name}"
              end

              if config.subresource_integrity.any?
                result << "--sri=#{escape(config.subresource_integrity.join(','))}"
              end

              result
            end

            def slice_assets?(slice)
              slice.root.join("assets").directory?
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
