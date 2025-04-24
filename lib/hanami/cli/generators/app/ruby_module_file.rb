# frozen_string_literal: true

require_relative "../constants"

module Hanami
  module CLI
    module Generators
      module App
        # @since x.x.x
        # @api private
        class RubyModuleFile < RubyFile
          private

          def modules
            namespace_modules + [constant_name]
          end

          def class_name
            nil
          end

          def parent_class
            nil
          end
        end
      end
    end
  end
end
