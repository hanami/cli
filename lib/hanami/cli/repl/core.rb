# frozen_string_literal: true

require "hanami/console/context"

module Hanami
  module CLI
    module Repl
      # @api private
      class Core
        # @api private
        attr_reader :application

        # @api private
        attr_reader :opts

        # @api private
        def initialize(application, opts)
          @application = application
          @opts = opts
        end

        # @api private
        def start
          raise NotImplementedError
        end

        # @api private
        def context
          @context ||= Hanami::Console::Context.new(application)
        end

        # @api private
        def prompt
          "#{name}[#{env}]"
        end

        # @api private
        def name
          (application.container.config.name || inflector.underscore(application.name))
            .split("/")[0]
        end

        # @api private
        def env
          application.container.env
        end

        # @api private
        def inflector
          application.inflector
        end
      end
    end
  end
end
