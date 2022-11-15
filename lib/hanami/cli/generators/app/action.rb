# frozen_string_literal: true

require "erb"
require "dry/files"
require_relative "../../errors"

# rubocop:disable Metrics/ParameterLists
module Hanami
  module CLI
    module Generators
      module App
        class Action
          def initialize(fs:, inflector:)
            @fs = fs
            @inflector = inflector
          end

          # rubocop:disable Layout/LineLength
          def call(app, controller, action, url, http, format, skip_view, slice, context: ActionContext.new(inflector, app, slice, controller, action))
            if slice
              generate_for_slice(controller, action, url, http, format, skip_view, slice, context)
            else
              generate_for_app(controller, action, url, http, format, skip_view, context)
            end
          end
          # rubocop:enable Layout/LineLength

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

          PATH_SEPARATOR = "/"
          private_constant :PATH_SEPARATOR

          attr_reader :fs

          attr_reader :inflector

          def generate_for_slice(controller, action, url, http, _format, _skip_view, slice, context)
            slice_directory = fs.join("slices", slice)
            raise MissingSliceError.new(slice) unless fs.directory?(slice_directory)

            fs.inject_line_at_block_bottom(
              fs.join("config", "routes.rb"),
              slice_matcher(slice),
              route(controller, action, url, http)
            )

            fs.mkdir(directory = fs.join(slice_directory, "actions", controller))
            fs.write(fs.join(directory, "#{action}.rb"), t("slice_action.erb", context))

            # unless skip_view
            #   fs.mkdir(directory = fs.join(slice_directory, "views", controller))
            #   fs.write(fs.join(directory, "#{action}.rb"), t("view.erb", context))
            #
            #   fs.mkdir(directory = fs.join(slice_directory, "templates", controller))
            #   fs.write(fs.join(directory, "#{action}.#{format}.erb"), t(template_format(format), context))
            # end
          end

          def generate_for_app(controller, action, url, http, _format, _skip_view, context)
            fs.inject_line_at_class_bottom(
              fs.join("config", "routes.rb"),
              "class Routes",
              route(controller, action, url, http)
            )

            fs.mkdir(directory = fs.join("app", "actions", controller))
            fs.write(fs.join(directory, "#{action}.rb"), t("action.erb", context))
          end

          def slice_matcher(slice)
            /slice[[:space:]]*:#{slice}/
          end

          def route(controller, action, url, http)
            %(#{route_http(action,
                           http)} "#{route_url(controller, action, url)}", to: "#{controller.join('.')}.#{action}")
          end

          def template_format(format)
            case format.to_sym
            when :html
              "template.html.erb"
            else
              "template.erb"
            end
          end

          def template(path, context)
            require "erb"

            ERB.new(
              File.read(__dir__ + "/action/#{path}")
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
