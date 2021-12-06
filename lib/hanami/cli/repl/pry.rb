# frozen_string_literal: true

require "pry"
require_relative "core"

module Hanami
  module CLI
    module Repl
      # @since 2.0.0
      # @api public
      class Pry < Core
        # @api private
        class Context # rubocop:disable Lint/EmptyClass
        end

        # @api public
        def start
          ::Pry.config.prompt = ::Pry::Prompt.new(
            "hanami",
            "my custom prompt",
            [proc { |*| "#{prompt}> " }]
          )

          ::Pry.start(Context.new.extend(context))
        end
      end
    end
  end
end
