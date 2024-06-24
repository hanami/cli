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
            @camelized_app_name = inflector.camelize(app_namespace).gsub(/[^\p{Alnum}]/, "")
            @key = key
            namespaces = key.split(KEY_SEPARATOR)[..-2]

            if slice
              slice_directory = fs.join("slices", slice)
              raise MissingSliceError.new(slice) unless fs.directory?(slice_directory)
            end

            fs.mkdir(directory(slice, namespaces: namespaces))

            if namespaces.none?
              out.puts(
                "  Generating a top-level operation. " \
                "To generate into a directory, add a namespace: `my_namespace.#{operation_name}`"
              )
            end

            path = fs.join(directory(slice, namespaces: namespaces), "#{operation_name}.rb")

            fs.write(path, class_definition(slice, namespaces: namespaces))
          end

          private

          attr_reader :fs, :inflector, :out

          def operation_name
            @key.split(KEY_SEPARATOR)[-1]
          end

          def camelized_operation_name
            inflector.camelize(operation_name).gsub(/[^\p{Alnum}]/, "")
          end

          def camelized_parent_operation_name(slice = nil)
            [highest_level_module(slice), "Operation"].join("::")
          end

          def highest_level_module(slice)
            if slice
              inflector.camelize(slice).gsub(/[^\p{Alnum}]/, "")
            else
              @camelized_app_name
            end
          end

          def camelized_modules(slice = nil, namespaces:)
            if namespaces.any?
              [highest_level_module(slice)].push(namespaces.map { inflector.camelize(_1) }).flatten
            else
              [highest_level_module(slice)]
            end
          end

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

          def class_definition(slice, namespaces:)
            RubyFileGenerator.class(
              camelized_operation_name,
              parent_class: camelized_parent_operation_name(slice),
              modules: camelized_modules(slice, namespaces: namespaces),
              methods: {call: nil}
            )
          end
        end
      end
    end
  end
end
