# frozen_string_literal: true

require "hanami/console/context"

require_relative "../app/command"

module Hanami
  module CLI
    module Commands
      module App
        # @api public
        class Console < App::Command
          ENGINES = {
            "pry" => -> (*args) {
              begin
                require "hanami/cli/repl/pry"
                Repl::Pry.new(*args)
              rescue LoadError # rubocop:disable Lint/SuppressedException
              end
            },
            "irb" => -> (*args) {
              require "hanami/cli/repl/irb"
              Repl::Irb.new(*args)
            },
          }.freeze
          private_constant :ENGINES

          DEFAULT_ENGINE = "irb"
          private_constant :DEFAULT_ENGINE

          desc "Start app console (REPL)"

          option :engine, required: false, desc: "Console engine", values: ENGINES.keys

          # @api private
          def call(engine: nil, **opts)
            console_engine = resolve_engine(engine, opts)

            if console_engine.nil?
              err.puts "`#{engine}' is not bundled. Please run `bundle add #{engine}' and retry."
              exit(1)
            end

            console_engine.start
          end

          private

          def resolve_engine(engine, opts)
            if engine
              ENGINES.fetch(engine).(app, opts)
            else
              ENGINES.map { |(_, loader)| loader.(app, opts) }.compact.first
            end
          end
        end
      end
    end
  end
end
