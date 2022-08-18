# frozen_string_literal: true

require "dry/files"
require_relative "../db/utils/database"

module Hanami
  module CLI
    module Commands
      module App
        class Command < Hanami::CLI::Command
          ACTION_SEPARATOR = "."

          module Environment
            def call(*args, **opts)
              env = opts[:env]

              hanami_env = env ? env.to_s : ENV.fetch("HANAMI_ENV", "development")

              ENV["HANAMI_ENV"] = hanami_env

              super(*args, **opts)
            end
          end

          def self.inherited(klass)
            super
            klass.prepend(Environment)
          end

          def app
            @app ||=
              begin
                require "hanami/prepare"
                Hanami.app
              end
          end

          def run_command(klass, *args)
            klass.new(
              out: out,
              inflector: app.inflector,
              fs: Dry::Files
            ).call(*args)
          end

          def measure(desc)
            start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            result = yield
            stop = Process.clock_gettime(Process::CLOCK_MONOTONIC)

            if result
              out.puts "=> #{desc} in #{(stop - start).round(4)}s"
            else
              out.puts "!!! => #{desc.inspect} FAILED"
            end
          end

          def database
            @database ||= Commands::DB::Utils::Database[app]
          end

          def database_config
            database.config
          end
        end
      end
    end
  end
end
