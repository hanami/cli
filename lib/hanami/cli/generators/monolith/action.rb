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

          def call(slice, controller, action, context: ActionContext.new(inflector, slice, controller, action))
            fs.mkdir(directory = "slices/#{slice}/actions/#{controller}")
            fs.chdir(directory) do
              fs.write("#{action}.rb", t("action.erb", context))
            end

            fs.mkdir(directory = "slices/#{slice}/views/#{controller}")
            fs.chdir(directory) do
              fs.write("#{action}.rb", t("view.erb", context))
            end

            fs.mkdir(directory = "slices/#{slice}/templates/#{controller}")
            fs.chdir(directory) do
              fs.write("#{action}.html.erb", t("template.erb", context))
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
