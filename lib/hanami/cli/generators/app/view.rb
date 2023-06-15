# frozen_string_literal: true

require "erb"
require "dry/files"
require_relative "../../errors"

# rubocop:disable Metrics/ParameterLists
module Hanami
  module CLI
    module Generators
      module App
        # @since 2.0.0
        # @api private
        class View
          # @since 2.0.0
          # @api private
          def initialize(fs:, inflector:)
            @fs = fs
            @inflector = inflector
          end

          # rubocop:disable Layout/LineLength

          # @since 2.0.0
          # @api private
          def call(app, key, format, slice)
            context = ViewContext.new(inflector, app, slice, key)

            if slice
              generate_for_slice(context, format, slice)
            else
              generate_for_app(context, format, slice)
            end
          end

          # rubocop:enable Layout/LineLength

          private

          attr_reader :fs

          attr_reader :inflector

          # rubocop:disable Metrics/AbcSize

          def generate_for_slice(context, format, slice)
            slice_directory = fs.join("slices", slice)
            raise MissingSliceError.new(slice) unless fs.directory?(slice_directory)

            fs.mkdir(directory = fs.join(slice_directory, "views", context.namespaces))
            fs.write(fs.join(directory, "#{context.name}.rb"), t("slice_view.erb", context))

            fs.mkdir(directory = fs.join(slice_directory, "templates", context.namespaces))
            fs.write(fs.join(directory, "#{context.name}.#{format}.erb"), t(template_with_format_ext("slice_template", format), context))
          end

          def generate_for_app(context, format, slice)
            fs.mkdir(directory = fs.join("app", "views", context.namespaces))
            fs.write(fs.join(directory, "#{context.name}.rb"), t("app_view.erb", context))

            fs.mkdir(directory = fs.join("app", "templates", context.namespaces))
            fs.write(fs.join(directory, "#{context.name}.#{format}.erb"), t(template_with_format_ext("app_template", format), context))
          end

          # rubocop:enable Metrics/AbcSize

          def template_with_format_ext(name, format)
            ext =
              case format.to_sym
              when :html
                ".html.erb"
              else
                ".erb"
              end

            "#{name}#{ext}"
          end

          def template(path, context)
            require "erb"

            ERB.new(
              File.read(__dir__ + "/view/#{path}")
            ).result(context.ctx)
          end

          alias_method :t, :template
        end
      end
    end
  end
end
# rubocop:enable Metrics/ParameterLists
