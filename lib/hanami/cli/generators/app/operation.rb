# frozen_string_literal: true

require "erb"
require "dry/files"
require_relative "../../errors"

module Hanami
  module CLI
    module Generators
      module App
        # @since x.x.x
        # @api private
        class Operation
          # @since x.x.x
          # @api private
          def initialize(fs:, inflector:)
            @fs = fs
            @inflector = inflector
          end

          # @since x.x.x
          # @api private
          def call(app, key, slice)
            context = OperationContext.new(inflector, app, slice, key)

            if slice
              generate_for_slice(context, slice)
            else
              generate_for_app(context)
            end
          end

          private

          attr_reader :fs

          attr_reader :inflector

          def generate_for_slice(context, slice)
            slice_directory = fs.join("slices", slice)
            raise MissingSliceError.new(slice) unless fs.directory?(slice_directory)

            if context.namespaces.any?
              fs.mkdir(directory = fs.join(slice_directory, "operations", context.namespaces))
              fs.write(fs.join(directory, "#{context.name}.rb"), t("nested_slice_operation.erb", context))
            else
              fs.mkdir(directory = fs.join(slice_directory, "operations"))
              fs.write(fs.join(directory, "#{context.name}.rb"), t("top_level_slice_operation.erb", context))
            end
          end

          def generate_for_app(context)
            if context.namespaces.any?
              fs.mkdir(directory = fs.join("app", "operations", context.namespaces))
              fs.write(fs.join(directory, "#{context.name}.rb"), t("nested_app_operation.erb", context))
            else
              fs.mkdir(directory = fs.join("app", "operations"))
              fs.write(fs.join(directory, "#{context.name}.rb"), t("top_level_app_operation.erb", context))
            end
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
