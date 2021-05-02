# frozen_string_literal: true

require "pry"
require_relative "core"

module Hanami
  module CLI
    module Repl
      class Pry < Core
        def start
          ::Pry.config.prompt = ::Pry::Prompt.new(
            "hanami",
            "my custom prompt",
            [proc { |*| "#{prompt}> " }]
          )

          ::Pry.start(context)
        end
      end
    end
  end
end
