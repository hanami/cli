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

          def file_contents
            RubyFileGenerator.module(
              modules,
              header: headers,
              body: body
            )
          end

          def modules
            local_namespaces
              .map { normalize(_1) }
              .compact
              .prepend(top_module)
              .append(normalize(constant_name))
          end
        end
      end
    end
  end
end
