# frozen_string_literal: true

require_relative "../constants"

module Hanami
  module CLI
    module Generators
      module App
        # @since 2.2.2
        # @api private
        class RubyClassFile < RubyFile
          def initialize(partially_qualified_parent: nil, fully_qualified_parent: nil, **args)
            super

            @partially_qualified_parent = partially_qualified_parent
            @fully_qualified_parent = fully_qualified_parent

            if partially_qualified_parent && fully_qualified_parent
              raise "Must provide only one of partially_qualified_parent or fully_qualified_parent"
            end
          end

          private

          # @since 2.2.2
          # @api private
          attr_reader(
            :partially_qualified_parent,
            :fully_qualified_parent,
          )

          # @since 2.2.2
          # @api private
          def file_contents
            RubyFileGenerator.class(
              normalize(constant_name),
              parent_class: parent_class,
              modules: modules,
              header: headers,
              body: body
            )
          end

          def modules
            local_namespaces
              .map { normalize(_1) }
              .compact
              .prepend(top_module)
          end

          def parent_class
            if partially_qualified_parent
              [top_module, partially_qualified_parent].join("::")
            else
              fully_qualified_parent
            end
          end
        end
      end
    end
  end
end
