# frozen_string_literal: true

require "erb"
require "dry/files"
require_relative "../../errors"

module Hanami
  module CLI
    module Generators
      module App
        # @since 2.0.0
        # @api private
        class Part
          # @since 2.0.0
          # @api private
          def initialize(fs:, inflector:)
            @fs = fs
            @inflector = inflector
          end

          # @since 2.0.0
          # @api private
          def call(app, key, slice)
            context = PartContext.new(inflector, app, slice, key)

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

            fs.mkdir(directory = fs.join(slice_directory, "views", "parts", *context.underscored_namespace))
            fs.write(fs.join(directory, "#{context.underscored_name}.rb"), t("slice_part.erb", context))
          end

          def generate_for_app(context)
            fs.mkdir(directory = fs.join("app", "views", "parts", *context.underscored_namespace))
            fs.write(fs.join(directory, "#{context.underscored_name}.rb"), t("app_part.erb", context))
          end

          def template(path, context)
            require "erb"

            ERB.new(
              File.read(__dir__ + "/part/#{path}"),
              trim_mode: "-"
            ).result(context.ctx)
          end

          alias_method :t, :template
        end
      end
    end
  end
end
