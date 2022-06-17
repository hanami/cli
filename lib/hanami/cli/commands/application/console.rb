# frozen_string_literal: true

require "hanami/console/context"

require_relative "../application/command"

module Hanami
  module CLI
    module Commands
      module Application
        # @api public
        class Console < Application::Command
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

          desc "Application REPL"

          option :repl, required: false, desc: "REPL gem that should be used ('pry' or 'irb')"

          # @api private
          def call(repl: nil, **opts)
            engine = resolve_engine(repl, opts)
            engine.start
          end

          private

          def resolve_engine(repl, opts)
            if repl
              REPLS.fetch(repl).(application, opts)
            else
              REPLS.map { |(_, loader)| loader.(application, opts) }.compact.first
            end
          end
        end
      end
    end
  end
end
