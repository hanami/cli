# frozen_string_literal: true

require "erb"
require "dry/files"
require_relative "../../errors"

module Hanami
  module CLI
    module Generators
      module App
        # @since 2.1.0
        # @api private
        class Part
          # @since 2.1.0
          # @api private
          def initialize(fs:, inflector:)
            @fs = fs
            @inflector = inflector
          end

          # @since 2.1.0
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

          # @since 2.1.0
          # @api private
          attr_reader :fs

          # @since 2.1.0
          # @api private
          attr_reader :inflector

          # @since 2.1.0
          # @api private
          def generate_for_slice(context, slice)
            slice_directory = fs.join("slices", slice)
            raise MissingSliceError.new(slice) unless fs.directory?(slice_directory)

            generate_base_part_for_app(context)
            generate_base_part_for_slice(context, slice)

            fs.mkdir(directory = fs.join(slice_directory, "views", "parts", *context.underscored_namespace))
            fs.create(fs.join(directory, "#{context.underscored_name}.rb"), t("slice_part.erb", context))
          end

          # @since 2.1.0
          # @api private
          def generate_for_app(context)
            generate_base_part_for_app(context)

            fs.mkdir(directory = fs.join("app", "views", "parts", *context.underscored_namespace))
            fs.create(fs.join(directory, "#{context.underscored_name}.rb"), t("app_part.erb", context))
          end

          # @since 2.1.0
          # @api private
          def generate_base_part_for_app(context)
            path = fs.join("app", "views", "part.rb")
            return if fs.exist?(path)

            fs.write(path, t("app_base_part.erb", context))
          end

          # @since 2.1.0
          # @api private
          def generate_base_part_for_slice(context, slice)
            path = fs.join("slices", slice, "views", "part.rb")
            return if fs.exist?(path)

            fs.write(path, t("slice_base_part.erb", context))
          end

          # @since 2.1.0
          # @api private
          def template(path, context)
            require "erb"

            ERB.new(
              File.read(__dir__ + "/part/#{path}"),
              trim_mode: "-"
            ).result(context.ctx)
          end

          # @since 2.1.0
          # @api private
          alias_method :t, :template
        end
      end
    end
  end
end
