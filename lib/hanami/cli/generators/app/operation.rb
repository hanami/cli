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
          def call(app, key, slice)
            context = OperationContext.new(inflector, app, slice, key)
            @app = app
            @key = key
            @namespaces = context.namespaces

            generate_file(context, slice)
          end

          private

          attr_reader :fs, :inflector, :out

          def camelized_app_name
            inflector.camelize(@app).gsub(/[^\p{Alnum}]/, "")
          end

          def camelized_operation_name
            key = @key.split(KEY_SEPARATOR)[-1]
            inflector.camelize(key).gsub(/[^\p{Alnum}]/, "")
          end

          def camelized_parent_operation_name(slice = nil)
            [highest_level_module(slice), "Operation"].join("::")
          end

          def highest_level_module(slice)
            if slice
              inflector.camelize(slice).gsub(/[^\p{Alnum}]/, "")
            else
              camelized_app_name
            end
          end

          def camelized_modules(slice = nil)
            if @namespaces.any?
              [highest_level_module(slice)].push(@namespaces.map { inflector.camelize(_1) }).flatten
            else
              [highest_level_module(slice)]
            end
          end

          def directory(slice = nil)
            base = if slice
                     fs.join("slices", slice)
                   else
                     fs.join("app")
                   end

            if @namespaces.any?
              fs.join(base, @namespaces)
            else
              fs.join(base)
            end
          end

          def generate_file(context, slice = nil)
            if slice
              slice_directory = fs.join("slices", slice)
              raise MissingSliceError.new(slice) unless fs.directory?(slice_directory)
            end

            class_definition = RubyFileGenerator.class(
              camelized_operation_name,
              parent_class: camelized_parent_operation_name(slice),
              modules: camelized_modules(slice),
              methods: {call: nil}
            )

            fs.mkdir(directory(slice))

            if context.namespaces.none?
              out.puts("  Generating a top-level operation. To generate into a directory, add a namespace: `my_namespace.#{context.name}`")
            end

            fs.write(fs.join(directory(slice), "#{context.name}.rb"), class_definition)
          end
        end
      end
    end
  end
end
