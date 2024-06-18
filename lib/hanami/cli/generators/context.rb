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

          %(gem "#{gem_name}", #{hanami_gem_version(name)})
        end

        # @since 2.0.0
        # @api private
        def hanami_gem_version(gem_name)
          if hanami_head?
            %(github: "hanami/#{gem_name}", branch: "main")
          else
            %("#{Version.gem_requirement}")
          end
        end

        # @since 2.1.0
        # @api private
        def hanami_assets_npm_package
          if hanami_head?
            %("hanami-assets": "hanami/assets-js#main")
          else
            %("hanami-assets": "#{Version.npm_package_requirement}")
          end
        end

        # @since 2.0.0
        # @api private
        def camelized_app_name
          inflector.camelize(app).gsub(/[^\p{Alnum}]/, "")
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

        # @since x.x.x
        # @api private
        def generate_db?
          !options.fetch(:skip_db, false)
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

        # @since 2.1.0
        # @api private
        #
        # @see https://rubyreferences.github.io/rubychanges/3.1.html#values-in-hash-literals-and-keyword-arguments-can-be-omitted
        def ruby_omit_hash_values?
          RUBY_VERSION >= "3.1"
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
