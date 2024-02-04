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
              pids = slices_with_assets.map { |slice| fork_child(slice) }

              Signal.trap("INT") do
                pids.each do |pid|
                  Process.kill(sig, pid)
                end
              end

              Process.waitall
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
            def fork_child(slice)
              Process.fork do
                cmd, *args = cmd_with_args(slice)
                system_call.call(cmd, *args, out_prefix: "[#{slice.slice_name}] ")
              rescue Interrupt
                # When this has been interrupted (by the Signal.trap handler in #call), catch the
                # interrupt and exit cleanly, without showing the default full backtrace.
              end
            end

            # @since 2.1.0
            # @api private
            def cmd_with_args(slice)
              cmd = [config.node_command, assets_config(slice).to_s, "--"]

              if slice.eql?(slice.app)
                cmd << "--path=app"
                cmd << "--target=public/assets"
              else
                cmd << "--path=#{slice.root.relative_path_from(slice.app.root)}"
                cmd << "--target=public/assets/#{slice.slice_name}"
              end

              cmd
            end

            def slices_with_assets
              slices = app.slices.with_nested + [app]
              slices.select { |slice| slice_assets?(slice) }
            end

            # @since 2.1.0
            # @api private
            def slice_assets?(slice)
              slice.root.join("assets").directory?
            end

            # @since 2.1.0
            # @api private
            def assets_config(slice)
              config = slice.root.join("config", "assets.js")
              return config if config.exist?

              config = slice.app.root.join("config", "assets.js")
              return config if config.exist?

              # TODO: real error
              raise "no asset config found"
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
