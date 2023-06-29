# frozen_string_literal: true

require_relative "version"

module Hanami
  module CLI
    # @since 2.0.0
    # @api private
    module Generators
      # @since 2.0.0
      # @api private
      class Context
        # @since 2.0.0
        # @api private
        def initialize(inflector, app)
          @inflector = inflector
          @app = app
        end

        # @since 2.0.0
        # @api private
        def ctx
          binding
        end

        # @since 2.0.0
        # @api private
        def hanami_version
          Version.gem_requirement
        end

        # @since 2.0.0
        # @api private
        def camelized_app_name
          inflector.camelize(app)
        end

        # @since 2.0.0
        # @api private
        def underscored_app_name
          inflector.underscore(app)
        end

        private

        attr_reader :inflector

        attr_reader :app
      end
    end
  end
end
