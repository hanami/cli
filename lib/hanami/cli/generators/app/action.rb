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
        class Action
          # @since 2.0.0
          # @api private
          def initialize(fs:, inflector:)
            @fs = fs
            @inflector = inflector
          end

          # @since 2.0.0
          # @api private
          def call(app, controller, action, url, http, format, skip_view, slice, context: nil)
            context ||= ActionContext.new(inflector, app, slice, controller, action)
            if slice
              generate_for_slice(controller, action, url, http, format, skip_view, slice, context)
            else
              generate_for_app(controller, action, url, http, format, skip_view, context)
            end
          end

          private

          ROUTE_HTTP_METHODS = %w[get post delete put patch trace options link unlink].freeze
          private_constant :ROUTE_HTTP_METHODS

          ROUTE_DEFAULT_HTTP_METHOD = "get"
          private_constant :ROUTE_DEFAULT_HTTP_METHOD

          ROUTE_RESTFUL_HTTP_METHODS = {
            "create" => "post",
            "update" => "patch",
            "destroy" => "delete"
          }.freeze
          private_constant :ROUTE_RESTFUL_HTTP_METHODS

          ROUTE_RESTFUL_URL_SUFFIXES = {
            "index" => [],
            "new" => ["new"],
            "create" => [],
            "edit" => [":id", "edit"],
            "update" => [":id"],
            "show" => [":id"],
            "destroy" => [":id"]
          }.freeze
          private_constant :ROUTE_RESTFUL_URL_SUFFIXES

          # @api private
          # @since 2.1.0
          RESTFUL_COUNTERPART_VIEWS = {
            "create" => "new",
            "update" => "edit"
          }.freeze
          private_constant :RESTFUL_COUNTERPART_VIEWS

          PATH_SEPARATOR = "/"
          private_constant :PATH_SEPARATOR

          attr_reader :fs

          attr_reader :inflector

          # rubocop:disable Metrics/AbcSize
          def generate_for_slice(controller, action, url, http, format, skip_view, slice, context)
            slice_directory = fs.join("slices", slice)
            raise MissingSliceError.new(slice) unless fs.directory?(slice_directory)

            fs.inject_line_at_block_bottom(
              fs.join("config", "routes.rb"),
              slice_matcher(slice),
              route(controller, action, url, http)
            )

            fs.mkdir(directory = fs.join(slice_directory, "actions", controller))
            fs.write(fs.join(directory, "#{action}.rb"), t("slice_action.erb", context))

            if generate_view?(skip_view, action, directory)
              fs.mkdir(directory = fs.join(slice_directory, "views", controller))
              fs.write(fs.join(directory, "#{action}.rb"), t("slice_view.erb", context))

              fs.mkdir(directory = fs.join(slice_directory, "templates", controller))
              fs.write(fs.join(directory, "#{action}.#{format}.erb"),
                       t(template_with_format_ext("slice_template", format), context))
            end
          end

          def generate_for_app(controller, action, url, http, format, skip_view, context)
            fs.inject_line_at_class_bottom(
              fs.join("config", "routes.rb"),
              "class Routes",
              route(controller, action, url, http)
            )

            fs.mkdir(directory = fs.join("app", "actions", controller))
            fs.write(fs.join(directory, "#{action}.rb"), t("action.erb", context))

            view = action
            view_directory = fs.join("app", "views", controller)

            if generate_view?(skip_view, view, view_directory)
              fs.mkdir(view_directory)
              fs.write(fs.join(view_directory, "#{view}.rb"), t("view.erb", context))

              fs.mkdir(template_directory = fs.join("app", "templates", controller))
              fs.write(fs.join(template_directory, "#{view}.#{format}.erb"),
                       t(template_with_format_ext("template", format), context))
            end
          end
          # rubocop:enable Metrics/AbcSize

          def slice_matcher(slice)
            /slice[[:space:]]*:#{slice}/
          end

          def route(controller, action, url, http)
            %(#{route_http(action,
                           http)} "#{route_url(controller, action, url)}", to: "#{controller.join('.')}.#{action}")
          end

          # @api private
          # @since 2.1.0
          def generate_view?(skip_view, view, directory)
            return false if skip_view
            return generate_restful_view?(view, directory) if rest_view?(view)

            true
          end

          # @api private
          # @since 2.1.0
          def generate_restful_view?(view, directory)
            corresponding_action = corresponding_restful_view(view)

            !fs.exist?(fs.join(directory, "#{corresponding_action}.rb"))
          end

          # @api private
          # @since 2.1.0
          def rest_view?(view)
            RESTFUL_COUNTERPART_VIEWS.keys.include?(view)
          end

          # @api private
          # @since 2.1.0
          def corresponding_restful_view(view)
            RESTFUL_COUNTERPART_VIEWS.fetch(view, nil)
          end

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
              File.read(__dir__ + "/action/#{path}"), trim_mode: "-",
            ).result(context.ctx)
          end

          alias_method :t, :template

          def route_url(controller, action, url)
            action = ROUTE_RESTFUL_URL_SUFFIXES.fetch(action) { [action] }
            url ||= "#{PATH_SEPARATOR}#{(controller + action).join(PATH_SEPARATOR)}"

            CLI::URL.call(url)
          end

          def route_http(action, http)
            result = (http ||= ROUTE_RESTFUL_HTTP_METHODS.fetch(action, ROUTE_DEFAULT_HTTP_METHOD)).downcase

            unless ROUTE_HTTP_METHODS.include?(result)
              raise UnknownHTTPMethodError.new(http)
            end

            result
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/ParameterLists
