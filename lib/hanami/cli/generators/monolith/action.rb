# frozen_string_literal: true

require "erb"
require "dry/cli/utils/files"
require "hanami/cli/generators/monolith/action_context"

module Hanami
  module CLI
    module Generators
      module Monolith
        class Action
          def initialize(fs:, inflector:)
            @fs = fs
            @inflector = inflector
          end

          def call(slice, controller, action, context: ActionContext.new(inflector, slice, controller, action)) # rubocop:disable Metrics/AbcSize
            slice_directory = fs.join("slices", slice)
            raise ArgumentError.new("slice not found `#{slice}'") unless fs.directory?(slice_directory)

            fs.chdir(slice_directory) do
              fs.mkdir(directory = fs.join("actions", controller))
              fs.write(fs.join(directory, "#{action}.rb"), t("action.erb", context))

              fs.mkdir(directory = fs.join("views", controller))
              fs.write(fs.join(directory, "#{action}.rb"), t("view.erb", context))

              fs.mkdir(directory = fs.join("templates", controller))
              fs.write(fs.join(directory, "#{action}.html.erb"), t("template.erb", context))
            end
          end

          private

          attr_reader :fs

          attr_reader :inflector

          def template(path, context)
            require "erb"

            ERB.new(
              File.read(__dir__ + "/action/#{path}")
            ).result(context.ctx)
          end

          alias_method :t, :template
        end
      end
    end
  end
end
