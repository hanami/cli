# frozen_string_literal: true

require "erb"
require "dry/files"
require_relative "../../errors"

module Hanami
  module CLI
    module Generators
      module App
        # @since 2.2.0
        # @api private
        class Operation
          KEY_SEPARATOR = %r{\.|/}
          # @since 2.2.0
          # @api private
          def initialize(fs:, inflector:, out: $stdout)
            @fs = fs
            @inflector = inflector
            @out = out
          end

          # @since 2.2.0
          # @api private
          def call(app_namespace, key, slice)
            operation_name = key.split(KEY_SEPARATOR)[-1]
            namespaces = key.split(KEY_SEPARATOR)[..-2]
            container_namespace = slice || app_namespace

            raise_missing_slice_error_if_missing(slice) if slice
            print_namespace_recommendation(operation_name) if namespaces.none?

            directory = directory(slice, namespaces: namespaces)
            path = fs.join(directory, "#{operation_name}.rb")
            fs.mkdir(directory)

            file_contents = class_definition(
              container_namespace: container_namespace,
              operation_name: operation_name,
              namespaces: namespaces,
            )
            fs.write(path, file_contents)
          end

          private

          attr_reader :fs, :inflector, :out

          def directory(slice = nil, namespaces:)
            base = if slice
                     fs.join("slices", slice)
                   else
                     fs.join("app")
                   end

            if namespaces.any?
              fs.join(base, namespaces)
            else
              fs.join(base)
            end
          end

          def class_definition(container_namespace:, operation_name:, namespaces:)
            camelized_modules = namespaces
              .map { camelize(_1) }
              .compact
              .prepend(camelize(container_namespace))

            parent_class = [camelize(container_namespace), "Operation"].join("::")

            RubyFileGenerator.class(
              camelize(operation_name),
              parent_class: parent_class,
              modules: camelized_modules,
              methods: {call: nil}
            )
          end

          def camelize(input)
            inflector.camelize(input).gsub(/[^\p{Alnum}]/, "")
          end

          def print_namespace_recommendation(operation_name)
            out.puts(
              "  Generating a top-level operation. " \
              "To generate into a directory, add a namespace: `my_namespace.#{operation_name}`"
            )
          end

          def raise_missing_slice_error_if_missing(slice)
            if slice
              slice_directory = fs.join("slices", slice)
              raise MissingSliceError.new(slice) unless fs.directory?(slice_directory)
            end
          end
        end
      end
    end
  end
end
