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

            def call(**)
              slices = app.slices.with_nested + [app]

              # capture pids here
              start_children(slices)
            end



            private

            def start_children(slices)
              slices.each do |slice|
                fork_child(slice)
              end

              Process.waitall
            end

            def fork_child(slice)
              Process.fork do
                cmd, *args = cmd_with_args(slice)
                p cmd_with_args(slice)
                result = system_call.call(cmd, *args)

                if result.exit_code == 0 # rubocop:disable Style/NumericPredicate TODO disable this entirely
                  puts result.out

                  if result.err && result.err != ""
                    puts ""
                    puts result.err
                  end
                else
                  puts "AssetsCompilationError"
                  puts result.out
                  puts result.err
                  raise "AssetsCompilationError"
                  # raise AssetsCompilationError.new(result.out, result.err)
                end
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
