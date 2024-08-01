# frozen_string_literal: true

require_relative "../constants"

module Hanami
  module CLI
    module Generators
      module App
        # @since 2.2.0
        # @api private
        class Operation
          # @since 2.2.0
          # @api private
          def initialize(fs:, inflector:, out: $stdout)
            @fs = fs
            @inflector = inflector
            @out = out
          end

          # @since 2.2.0
          # @api private
          def call(key:, namespace:, base_path:)
            RubyFileWriter.new(
              fs: fs,
              inflector: inflector,
            ).call(
              namespace: namespace,
              base_path: base_path,
              key: key,
              relative_parent_class: "Operation",
              body: ["def call", "end"],
            )

            unless key.match?(KEY_SEPARATOR)
              out.puts(
                "  Note: We generated a top-level operation. " \
                "To generate into a directory, add a namespace: `my_namespace.add_book`"
              )
            end
          end

          private

          attr_reader :fs, :inflector, :out
        end
      end
    end
  end
end
