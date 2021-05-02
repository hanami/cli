# frozen_string_literal: true

require "hanami/console/context"

module Hanami
  module CLI
    module Repl
      class Core
        attr_reader :application

        attr_reader :opts

        def initialize(application, opts)
          @application = application
          @opts = opts
        end

        def start
          raise NotImplementedError
        end

        def context
          Hanami::Console::Context.new(application)
        end

        def prompt
          "#{name}[#{env}]"
        end

        def name
          (application.container.config.name || inflector.underscore(application.name))
            .split("/")[0]
        end

        def env
          application.container.env
        end

        def inflector
          application.inflector
        end
      end
    end
  end
end
