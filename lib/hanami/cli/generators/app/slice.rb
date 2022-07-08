# frozen_string_literal: true

require "erb"
require "dry/files"
require "hanami/cli/generators/app/slice_context"

module Hanami
  module CLI
    module Generators
      module App
        class Slice
          def initialize(fs:, inflector:)
            @fs = fs
            @inflector = inflector
          end

          def call(app, slice, slice_url_prefix, context: SliceContext.new(inflector, app, slice, slice_url_prefix)) # rubocop:disable Metrics/AbcSize
            fs.inject_line_before_last(fs.join("config", "routes.rb"), /end/, t("routes.erb", context).chomp)

            fs.mkdir(directory = "slices/#{slice}")

            fs.chdir(directory) do
              fs.write("action.rb", t("action.erb", context))
              fs.write("view.rb", t("view.erb", context))
              fs.write("entities.rb", t("entities.erb", context))
              fs.write("repository.rb", t("repository.erb", context))

              fs.write("actions/.keep", t("keep.erb", context))
              fs.write("views/.keep", t("keep.erb", context))
              fs.write("templates/.keep", t("keep.erb", context))
              fs.write("templates/layouts/.keep", t("keep.erb", context))
              fs.write("entities/.keep", t("keep.erb", context))
              fs.write("repositories/.keep", t("keep.erb", context))
            end
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
