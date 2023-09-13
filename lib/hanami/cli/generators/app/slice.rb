# frozen_string_literal: true

require "erb"
require "dry/files"

module Hanami
  module CLI
    module Generators
      module App
        # @since 2.0.0
        # @api private
        class Slice
          # @since 2.0.0
          # @api private
          def initialize(fs:, inflector:)
            @fs = fs
            @inflector = inflector
          end

          # @since 2.0.0
          # @api private
          def call(app, slice, url, context: SliceContext.new(inflector, app, slice, url)) # rubocop:disable Metrics/AbcSize
            fs.inject_line_at_class_bottom(
              fs.join("config", "routes.rb"), "class Routes", t("routes.erb", context).chomp
            )

            fs.mkdir(directory = "slices/#{slice}")

            # fs.write("#{directory}/config/slice.rb", t("slice.erb", context))
            fs.write(fs.join(directory, "action.rb"), t("action.erb", context))
            fs.write(fs.join(directory, "view.rb"), t("view.erb", context))
            fs.write(fs.join(directory, "views", "helpers.rb"), t("helpers.erb", context))
            fs.write(fs.join(directory, "templates", "layouts", "app.html.erb"), t("app_layout.erb", context))

            if context.bundled_assets?
              fs.write(fs.join(directory, "assets", "javascripts", "app.js"), t("app_js.erb", context))
              fs.write(fs.join(directory, "assets", "stylesheets", "app.css"), t("app_css.erb", context))
            end

            # fs.write(fs.join(directory, "/entities.rb"), t("entities.erb", context))
            # fs.write(fs.join(directory, "/repository.rb"), t("repository.erb", context))

            fs.write(fs.join(directory, "actions/.keep"), t("keep.erb", context))
            fs.write(fs.join(directory, "views/.keep"), t("keep.erb", context))
            fs.write(fs.join(directory, "templates/.keep"), t("keep.erb", context))
            fs.write(fs.join(directory, "templates/layouts/.keep"), t("keep.erb", context))
            # fs.write(fs.join(directory, entities/.keep"), t("keep.erb", context))
            # fs.write(fs.join(directory, repositories/.keep"), t("keep.erb", context))
          end

          private

          attr_reader :fs

          attr_reader :inflector

          def template(path, context)
            require "erb"

            ERB.new(
              File.read(__dir__ + "/slice/#{path}"),
              trim_mode: "-"
            ).result(context.ctx)
          end

          alias_method :t, :template
        end
      end
    end
  end
end
