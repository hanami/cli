# frozen_string_literal: true
require_relative "../constants"

module Hanami
  module CLI
    module Generators
      module App
        class ComponentContext < SliceContext
          # @api private
          # @since 2.2.0
          attr_reader :key

          # @api private
          # @since 2.2.0
          def initialize(inflector, app, slice, key)
            @key = key
            super(inflector, app, slice, nil)
          end

          # @api private
          # @since 2.2.0
          def namespaces
            @namespaces ||= key.split(MATCHER_PATTERN)[..-2].map { inflector.underscore(_1) }
          end

          # @api private
          # @since 2.2.0
          def name
            @name ||= key.split(MATCHER_PATTERN)[-1]
          end

          # @api private
          # @since 2.2.0
          def camelized_namespace
            namespaces.map { inflector.camelize(_1) }.join(NAMESPACE_SEPARATOR)
          end

          # @api private
          # @since 2.2.0
          def camelized_name
            inflector.camelize(name)
          end

          # @api private
          # @since 2.2.0
          def underscored_namespace
            namespaces.map { inflector.underscore(_1) }
          end

          # @api private
          # @since 2.2.0
          def underscored_name
            inflector.underscore(name)
          end

          # @api private
          # @since 2.2.0
          def module_namespace_declaration
            namespaces.each_with_index.map { |token, i|
              "#{OFFSET}#{INDENTATION * i}module #{inflector.camelize(token)}"
            }.join($/)
          end

          # @api private
          # @since 2.2.0
          def module_namespace_end
            namespaces.each_with_index.map { |_, i|
              "#{OFFSET}#{INDENTATION * i}end"
            }.reverse.join($/)
          end

          # @api private
          # @since 2.2.0
          def module_namespace_offset
            "#{OFFSET}#{INDENTATION * namespaces.count}"
          end
        end
      end
    end
  end
end
