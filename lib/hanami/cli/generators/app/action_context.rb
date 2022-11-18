# frozen_string_literal: true

require_relative "./slice_context"
require "dry/files/path"

module Hanami
  module CLI
    module Generators
      # @since 2.0.0
      # @api private
      module App
        # @since 2.0.0
        # @api private
        class ActionContext < SliceContext
          # @since 2.0.0
          # @api private
          def initialize(inflector, app, slice, controller, action)
            @controller = controller
            @action = action
            super(inflector, app, slice, nil)
          end

          # @since 2.0.0
          # @api private
          def camelized_controller_name
            controller.map do |token|
              inflector.camelize(token)
            end.join(NAMESPACE_SEPARATOR)
          end

          # @since 2.0.0
          # @api private
          def camelized_action_name
            inflector.camelize(action)
          end

          # @since 2.0.0
          # @api private
          def underscored_controller_name
            controller.map do |token|
              inflector.underscore(token)
            end
          end

          # @since 2.0.0
          # @api private
          def underscored_action_name
            inflector.underscore(action)
          end

          # @since 2.0.0
          # @api private
          def module_controller_declaration
            controller.each_with_index.map do |token, i|
              "#{OFFSET}#{INDENTATION * i}module #{inflector.camelize(token)}"
            end.join($/)
          end

          # @since 2.0.0
          # @api private
          def module_controller_end
            controller.each_with_index.map do |_, i|
              "#{OFFSET}#{INDENTATION * i}end"
            end.reverse.join($/)
          end

          # @since 2.0.0
          # @api private
          def module_controller_offset
            "#{OFFSET}#{INDENTATION * controller.count}"
          end

          # @since 2.0.0
          # @api private
          def template_path
            Dry::Files::Path["slices", underscored_slice_name, "templates", *underscored_controller_name,
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
