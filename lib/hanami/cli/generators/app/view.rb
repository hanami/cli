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
        class View
          # @since 2.0.0
          # @api private
          def initialize(fs:, inflector:)
            @fs = fs
            @inflector = inflector
          end

          # @since 2.0.0
          # @api private
          def call(app, key, format, engine, slice)
            context = ViewContext.new(inflector, app, slice, key)

            if slice
              generate_for_slice(context, format, engine, slice)
            else
              generate_for_app(context, format, engine, slice)
            end
          end

          private

          attr_reader :fs

          attr_reader :inflector

          # rubocop:disable Metrics/AbcSize

          def generate_for_slice(context, format, engine, slice)
            slice_directory = fs.join("slices", slice)
            raise MissingSliceError.new(slice) unless fs.directory?(slice_directory)

            fs.mkdir(directory = fs.join(slice_directory, "views", context.namespaces))
            fs.create(fs.join(directory, "#{context.name}.rb"), t("slice_view.erb", context))

            fs.mkdir(directory = fs.join(slice_directory, "templates", context.namespaces))
            fs.create(fs.join(directory, "#{context.name}.#{format}.#{engine}"),
                      t(template_with_format_ext("slice_template", format, engine), context))
          end

          def generate_for_app(context, format, engine, _slice)
            fs.mkdir(directory = fs.join("app", "views", context.namespaces))
            fs.create(fs.join(directory, "#{context.name}.rb"), t("app_view.erb", context))

            fs.mkdir(directory = fs.join("app", "templates", context.namespaces))
            fs.create(fs.join(directory, "#{context.name}.#{format}.#{engine}"),
                      t(template_with_format_ext("app_template", format, engine), context))
          end

          # rubocop:enable Metrics/AbcSize

          def template_with_format_ext(name, format, engine)
            ext =
              case format.to_sym
              when :html
                ".html.#{engine}"
              else
                ".#{engine}"
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
