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

            if slice
              generate_for_slice(context, slice)
            else
              generate_for_app(context)
            end
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

          def camelized_parent_operation_name
            [camelized_app_name, "Operation"].join("::")
          end

          def camelized_modules
            if @namespaces.any?
              [camelized_app_name].push(@namespaces.map { inflector.camelize(_1) }).flatten
            else
              [camelized_app_name]
            end
          end

          def directory
            if @namespaces.any?
              fs.join("app", @namespaces)
            else
              fs.join("app")
            end
          end

          def generate_for_slice(context, slice)
            slice_directory = fs.join("slices", slice)
            raise MissingSliceError.new(slice) unless fs.directory?(slice_directory)

            if context.namespaces.any?
              fs.mkdir(directory = fs.join(slice_directory, context.namespaces))
              fs.write(fs.join(directory, "#{context.name}.rb"), t("nested_slice_operation.erb", context))
            else
              fs.mkdir(directory = fs.join(slice_directory))
              fs.write(fs.join(directory, "#{context.name}.rb"), t("top_level_slice_operation.erb", context))
              out.puts("  Generating a top-level operation. To generate into a directory, add a namespace: `my_namespace.#{context.name}`")
            end
          end

          def generate_for_app(context)
            class_definition = RubyFileGenerator.class(
              camelized_operation_name,
              parent_class: camelized_parent_operation_name,
              modules: camelized_modules,
              methods: {call: nil}
            )

            fs.mkdir(directory)
            if context.namespaces.none?
              out.puts("  Generating a top-level operation. To generate into a directory, add a namespace: `my_namespace.#{context.name}`")
            end
            fs.write(fs.join(directory, "#{context.name}.rb"), class_definition)
          end

          def template(path, context)
            require "erb"

            ERB.new(
              File.read(__dir__ + "/operation/#{path}")
            ).result(context.ctx)
          end

          alias_method :t, :template
        end
      end
    end
  end
end
