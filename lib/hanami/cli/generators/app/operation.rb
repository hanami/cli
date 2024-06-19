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
              fs.mkdir(directory = fs.join(slice_directory, context.namespaces))
              fs.write(fs.join(directory, "#{context.name}.rb"), t("slice_operation.erb", context))
            else
              print_error_message_about_naming(context.name, slice_directory)
            end
          end

          def generate_for_app(context)
            if context.namespaces.any?
              fs.mkdir(directory = fs.join("app", context.namespaces))
              fs.write(fs.join(directory, "#{context.name}.rb"), t("app_operation.erb", context))
            else
              print_error_message_about_naming(context.name, "app")
            end
          end

          def template(path, context)
            require "erb"

            ERB.new(
              File.read(__dir__ + "/operation/#{path}")
            ).result(context.ctx)
          end

          def print_error_message_about_naming(provided_name, base_location)
            raise NameNeedsNamespaceError.new(
              "Failed to create operation `#{provided_name}'. " \
              "This would create the operation directly in the `#{base_location}/' folder. " \
              "Instead, you should provide a namespace for the folder where this operation will live. " \
              "NOTE: We recommend giving it a name that's specific to your domain, " \
              "but you can also use `operations.#{provided_name}' in the meantime if you're unsure."
            )
          end

          alias_method :t, :template
        end
      end
    end
  end
end
