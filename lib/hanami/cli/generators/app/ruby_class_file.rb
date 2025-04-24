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

          attr_reader :partially_qualified_parent, :fully_qualified_parent

          def class_name
            constant_name
          end

          def modules
            namespace_modules
          end

          def parent_class
            if partially_qualified_parent
              [normalize(namespace), partially_qualified_parent].join("::")
            else
              fully_qualified_parent
            end
          end
        end
      end
    end
  end
end
