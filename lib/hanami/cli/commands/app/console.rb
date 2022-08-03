# frozen_string_literal: true

require "hanami/console/context"

require_relative "../app/command"

module Hanami
  module CLI
    module Commands
      module App
        # @api public
        class Console < App::Command
          REPLS = {
            "pry" => -> (*args) {
              begin
                require "hanami/cli/repl/pry"
                Repl::Pry.new(*args)
              rescue LoadError; end # rubocop:disable Lint/SuppressedException
            },
            "irb" => -> (*args) {
              require "hanami/cli/repl/irb"
              Repl::Irb.new(*args)
            },
          }.freeze

          desc "App REPL"

          option :env, required: false, desc: "Application environment"
          option :repl, required: false, desc: "REPL gem that should be used ('pry' or 'irb')"

          # @api private
          def call(repl: nil, **opts)
            engine = resolve_engine(repl, opts)
            engine.start
          end

          private

          def resolve_engine(repl, opts)
            if repl
              REPLS.fetch(repl).(app, opts)
            else
              REPLS.map { |(_, loader)| loader.(app, opts) }.compact.first
            end
          end
        end
      end
    end
  end
end
