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
            camelized_app_name = inflector.camelize(app_namespace).gsub(/[^\p{Alnum}]/, "")
            operation_name = key.split(KEY_SEPARATOR)[-1]
            namespaces = key.split(KEY_SEPARATOR)[..-2]

            if slice
              slice_directory = fs.join("slices", slice)
              raise MissingSliceError.new(slice) unless fs.directory?(slice_directory)
            end

            directory = directory(slice, namespaces: namespaces)
            fs.mkdir(directory)

            if namespaces.none?
              out.puts(
                "  Generating a top-level operation. " \
                "To generate into a directory, add a namespace: `my_namespace.#{operation_name}`"
              )
            end

            highest_level_module =
              if slice
                inflector.camelize(slice).gsub(/[^\p{Alnum}]/, "")
              else
                camelized_app_name
              end

            path = fs.join(directory, "#{operation_name}.rb")

            file_contents = class_definition(highest_level_module: highest_level_module,
                                             operation_name: operation_name, namespaces: namespaces)

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

          def class_definition(highest_level_module:, operation_name:, namespaces:)
            camelized_operation_name = inflector.camelize(operation_name).gsub(/[^\p{Alnum}]/, "")

            camelized_modules = if namespaces.any?
                                  [highest_level_module].push(namespaces.map { inflector.camelize(_1) }).flatten
                                else
                                  [highest_level_module]
                                end

            parent_class = [highest_level_module, "Operation"].join("::")

            RubyFileGenerator.class(
              camelized_operation_name,
              parent_class: parent_class,
              modules: camelized_modules,
              methods: {call: nil}
            )
          end
        end
      end
    end
  end
end
