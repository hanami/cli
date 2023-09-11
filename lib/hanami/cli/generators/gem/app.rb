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
            fs.write(".gitignore", t("gitignore.erb", context))
            fs.write(".env", t("env.erb", context))

            fs.write("README.md", t("readme.erb", context))
            fs.write("Gemfile", t("gemfile.erb", context))
            fs.write("Rakefile", t("rakefile.erb", context))
            fs.write("Procfile.dev", t("procfile.erb", context))
            fs.write("config.ru", t("config_ru.erb", context))

            fs.write("config/app.rb", t("app.erb", context))
            fs.write("config/settings.rb", t("settings.erb", context))
            fs.write("config/routes.rb", t("routes.erb", context))
            fs.write("config/puma.rb", t("puma.erb", context))

            fs.write("lib/tasks/.keep", t("keep.erb", context))
            fs.write("lib/#{app}/types.rb", t("types.erb", context))

            fs.write("app/actions/.keep", t("keep.erb", context))
            fs.write("app/action.rb", t("action.erb", context))
            fs.write("app/view.rb", t("view.erb", context))
            fs.write("app/views/helpers.rb", t("helpers.erb", context))
            fs.write("app/templates/layouts/app.html.erb", File.read(File.join(__dir__, "app", "layouts_app.html.erb")))

            if Hanami.bundled?("hanami-assets")
              fs.write("app/assets/javascripts/.keep", t("keep.erb", context))
              fs.write("app/assets/stylesheets/.keep", t("keep.erb", context))
              fs.write("app/assets/images/favicon.ico", File.read(File.join(__dir__, "app", "favicon.ico")))
            end

            fs.write("public/404.html", File.read(File.join(__dir__, "app", "404.html")))
            fs.write("public/500.html", File.read(File.join(__dir__, "app", "500.html")))
          end

          def template(path, context)
            require "erb"

            ERB.new(
              File.read(File.join(__dir__, "app", path)),
              trim_mode: "-"
            ).result(context.ctx)
          end

          alias_method :t, :template
        end
      end
    end
  end
end
