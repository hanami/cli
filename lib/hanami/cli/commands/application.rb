# frozen_string_literal: true

require "dry/files"

require_relative "db/utils/database"

module Hanami
  module CLI
    module Commands
      class Application < Hanami::CLI::Command
        module Environment
          def call(**opts)
            env = opts[:env]

            hanami_env = env ? env.to_s : ENV["HANAMI_ENV"] || "development"

            ENV["HANAMI_ENV"] = hanami_env

            super(**opts)
          end
        end

        def self.inherited(klass)
          super
          klass.option(:env, required: false, desc: "Application's environment")
          klass.prepend(Environment)
        end

        def application
          @application ||=
            begin
              require "hanami/prepare"
              Hanami.application
            end
        end

        def run_command(klass, *args)
          klass.new(
            out: out,
            inflector: application.inflector,
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
          @database ||= Commands::DB::Utils::Database[application]
        end

        def database_config
          database.config
        end
      end
    end
  end
end
