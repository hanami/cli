# frozen_string_literal: true

require "hanami/console/context"
require_relative "../errors"

module Hanami
  module CLI
    module Repl
      # @api private
      class Core
        # @api private
        attr_reader :app

        # @api private
        attr_reader :opts

        # @api private
        def initialize(app, opts)
          @app = app
          @opts = opts
        end

        # @api private
        def start
          raise Hanami::CLI::NotImplementedError
        end

        # @api private
        def context
          @context ||= Hanami::Console::Context.new(app)
        end

        # @api private
        def prompt
          "#{name}[#{env}]"
        end

        # @api private
        def name
          (app.container.config.name || inflector.underscore(app.name))
            .to_s.split("/")[0]
        end

        # @api private
        def env
          app.container.env
        end

        # @api private
        def inflector
          app.inflector
        end
      end
    end
  end
end
