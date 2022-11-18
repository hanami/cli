# frozen_string_literal: true

require "erb"
require "shellwords"

module Hanami
  module CLI
    module Generators
      # @since 2.0.0
      # @api private
      module Gem
        # @since 2.0.0
        # @api private
        class App
          # @since 2.0.0
          # @api private
          def initialize(fs:, inflector:)
            super()
            @fs = fs
            @inflector = inflector
          end

          # @since 2.0.0
          # @api private
          def call(app, context: Context.new(inflector, app), &blk)
            generate_app(app, context)
            blk.call
          end

          private

          attr_reader :fs

          attr_reader :inflector

          def generate_app(app, context) # rubocop:disable Metrics/AbcSize
            fs.write(".env", t("env.erb", context))

            fs.write("README.md", t("readme.erb", context))
            fs.write("Gemfile", t("gemfile.erb", context))
            fs.write("Rakefile", t("rakefile.erb", context))
            fs.write("config.ru", t("config_ru.erb", context))

            fs.write("config/app.rb", t("app.erb", context))
            fs.write("config/settings.rb", t("settings.erb", context))
            fs.write("config/routes.rb", t("routes.erb", context))
            fs.write("config/puma.rb", t("puma.erb", context))

            fs.write("lib/tasks/.keep", t("keep.erb", context))
            fs.write("lib/#{app}/types.rb", t("types.erb", context))

            fs.write("app/actions/.keep", t("keep.erb", context))
            fs.write("app/action.rb", t("action.erb", context))
          end

          def template(path, context)
            require "erb"

            ERB.new(
              File.read(File.join(__dir__, "app", path))
            ).result(context.ctx)
          end

          alias_method :t, :template
        end
      end
    end
  end
end
