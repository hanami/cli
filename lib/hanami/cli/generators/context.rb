# frozen_string_literal: true

require "hanami/version"

module Hanami
  module CLI
    module Generators
      class Context
        def initialize(inflector, app)
          @inflector = inflector
          @app = app
        end

        def ctx
          binding
        end

        def hanami_version
          Hanami::Version.gem_requirement
        end

        def classified_app_name
          inflector.classify(app)
        end

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
