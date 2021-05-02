# frozen_string_literal: true

require "hanami/console/context"

require_relative "../application"

module Hanami
  module CLI
    module Commands
      module Monolith
        class Console < Application
          REPLS = {
            "irb" => -> *args {
              require "hanami/cli/repl/irb"
              Repl::Irb.new(*args)
            },
            "pry" => -> *args {
              require "hanami/cli/repl/pry"
              Repl::Pry.new(*args)
            }
          }.freeze

          desc "Application REPL"

          option :repl, required: false, default: "irb", desc: "REPL gem that should be used"

          def call(repl: "irb", **opts)
            REPLS.fetch(repl).(application, opts).start
          end
        end
      end
    end
  end
end
