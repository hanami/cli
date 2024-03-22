# frozen_string_literal: true

require "erb"
require "dry/files"
module Hanami
  module CLI
    module Generators
      module App
        # @api private
        class Component
          # @api private
          def initialize(fs:, inflector:)
            @fs = fs
            @inflector = inflector
          end

          # @api private
          def call(app, key, slice)
            context = ComponentContext.new(inflector, app, slice, key)

            if slice
              generate_for_slice(context, slice)
            else
              generate_for_app(context)
            end
          end

          private

          # @api private
          attr_reader :fs

          # @api private
          attr_reader :inflector

          # @api private
          def generate_for_slice(context, slice)
            slice_directory = fs.join("slices", slice)
            raise MissingSliceError.new(slice) unless fs.directory?(slice_directory)

            fs.mkdir(directory = fs.join(slice_directory, context.namespaces))
            fs.write(fs.join(directory, "#{context.underscored_name}.rb"), t("slice_component.erb", context))
          end

          # @api private
          def generate_for_app(context)
            fs.mkdir(directory = fs.join("app", context.namespaces))
            fs.write(fs.join(directory, "#{context.underscored_name}.rb"), t("component.erb", context))
          end

          def template(path, context)
            ERB.new(
              File.read(__dir__ + "/component/#{path}")
            ).result(context.ctx)
          end

          alias_method :t, :template
        end
      end
    end
  end
end
