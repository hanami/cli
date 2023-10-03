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
        def initialize(inflector, app, **options)
          @inflector = inflector
          @app = app
          @options = options
        end

        # @since 2.0.0
        # @api private
        def ctx
          binding
        end

        def hanami_gem(name)
          gem_name = name == "hanami" ? "hanami" : "hanami-#{name}"

          %(gem "#{gem_name}", #{hanami_version(name)})
        end

        # @since 2.0.0
        # @api private
        def hanami_version(gem_name)
          if hanami_head?
            %(github: "hanami/#{gem_name}", branch: "main")
          else
            %("#{Version.gem_requirement}")
          end
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

        # @since 2.1.0
        # @api private
        def humanized_app_name
          inflector.humanize(app)
        end

        # @since 2.1.0
        # @api private
        def hanami_head?
          options.fetch(:head)
        end

        # @since 2.1.0
        # @api private
        def generate_assets?
          !options.fetch(:skip_assets, false)
        end

        # @since 2.1.0
        # @api private
        def bundled_views?
          Hanami.bundled?("hanami-view")
        end

        # @since 2.1.0
        # @api private
        def bundled_assets?
          Hanami.bundled?("hanami-assets")
        end

        private

        # @since 2.0.0
        # @api private
        attr_reader :inflector

        # @since 2.0.0
        # @api private
        attr_reader :app

        # @since 2.1.0
        # @api private
        attr_reader :options
      end
    end
  end
end
