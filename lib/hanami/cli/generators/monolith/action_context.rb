# frozen_string_literal: true

require_relative "./slice_context"
require "dry/cli/utils/path"

module Hanami
  module CLI
    module Generators
      module Monolith
        class ActionContext < SliceContext
          def initialize(inflector, slice, controller, action)
            @controller = controller
            @action = action
            super(inflector, nil, slice)
          end

          def classified_controller_name
            controller.map do |token|
              inflector.camelize(token)
            end.join(NAMESPACE_SEPARATOR)
          end

          def classified_action_name
            inflector.classify(action)
          end

          def underscored_controller_name
            controller.map do |token|
              inflector.underscore(token)
            end
          end

          def underscored_action_name
            inflector.underscore(action)
          end

          def module_controller_declaration
            controller.each_with_index.map do |token, i|
              "#{OFFSET}#{INDENTATION * i}module #{inflector.camelize(token)}"
            end.join($/)
          end

          def module_controller_end
            controller.each_with_index.map do |_, i|
              "#{OFFSET}#{INDENTATION * i}end"
            end.reverse.join($/)
          end

          def module_controller_offset
            "#{OFFSET}#{INDENTATION * controller.count}"
          end

          def template_path
            Dry::CLI::Utils::Path["slices", underscored_slice_name, "templates", *underscored_controller_name,
                                  "#{underscored_action_name}.html.erb"]
          end

          private

          NAMESPACE_SEPARATOR = "::"
          private_constant :NAMESPACE_SEPARATOR

          INDENTATION = "  "
          private_constant :INDENTATION

          OFFSET = INDENTATION * 2
          private_constant :OFFSET

          attr_reader :controller

          attr_reader :action
        end
      end
    end
  end
end
