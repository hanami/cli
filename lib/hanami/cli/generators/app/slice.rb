# frozen_string_literal: true

require "erb"
require "dry/files"

module Hanami
  module CLI
    module Generators
      module App
        class Slice
          def initialize(fs:, inflector:)
            @fs = fs
            @inflector = inflector
          end

          def call(app, slice, url, context: SliceContext.new(inflector, app, slice, url))
            fs.inject_line_at_class_bottom(
              fs.join("config", "routes.rb"), "class Routes", t("routes.erb", context).chomp
            )

            fs.mkdir(directory = "slices/#{slice}")

            # fs.write("#{directory}/config/slice.rb", t("slice.erb", context))
            fs.write(fs.join(directory, "action.rb"), t("action.erb", context))
            # fs.write(fs.join(directory, "/view.rb"), t("view.erb", context))
            # fs.write(fs.join(directory, "/entities.rb"), t("entities.erb", context))
            # fs.write(fs.join(directory, "/repository.rb"), t("repository.erb", context))

            fs.write(fs.join(directory, "actions/.keep"), t("keep.erb", context))
            # fs.write(fs.join(directory, views/.keep"), t("keep.erb", context))
            # fs.write(fs.join(directory, templates/.keep"), t("keep.erb", context))
            # fs.write(fs.join(directory, templates/layouts/.keep"), t("keep.erb", context))
            # fs.write(fs.join(directory, entities/.keep"), t("keep.erb", context))
            # fs.write(fs.join(directory, repositories/.keep"), t("keep.erb", context))
          end

          private

          attr_reader :fs

          attr_reader :inflector

          def template(path, context)
            require "erb"

            ERB.new(
              File.read(__dir__ + "/slice/#{path}")
            ).result(context.ctx)
          end

          alias_method :t, :template
        end
      end
    end
  end
end
