# frozen_string_literal: true

require "erb"
require "dry/files"
require "hanami/cli/generators/app/action_context"
require "hanami/cli/url"

module Hanami
  module CLI
    module Generators
      module App
        class Action
          def initialize(fs:, inflector:)
            @fs = fs
            @inflector = inflector
          end

          # rubocop:disable Metrics/ParameterLists
          # rubocop:disable Layout/LineLength
          def call(controller, action, url, http, _format, _skip_view, slice, context: ActionContext.new(inflector, slice, controller, action))
            slice_directory = fs.join("slices", slice)
            raise ArgumentError.new("slice not found `#{slice}'") unless fs.directory?(slice_directory)

            fs.inject_line_at_block_bottom(
              fs.join("config", "routes.rb"),
              slice_matcher(slice),
              route(controller, action, url, http)
            )

            fs.chdir(slice_directory) do
              fs.mkdir(directory = fs.join("actions", controller))
              fs.write(fs.join(directory, "#{action}.rb"), t("action.erb", context))

              # unless skip_view
              #   fs.mkdir(directory = fs.join("views", controller))
              #   fs.write(fs.join(directory, "#{action}.rb"), t("view.erb", context))
              #
              #   fs.mkdir(directory = fs.join("templates", controller))
              #   fs.write(fs.join(directory, "#{action}.#{format}.erb"), t(template_format(format), context))
              # end
            end
          end
          # rubocop:enable Layout/LineLength
          # rubocop:enable Metrics/ParameterLists

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
            "index" => "",
            "new" => "/new",
            "create" => "",
            "edit" => "/:id/edit",
            "update" => "/:id",
            "show" => "/:id",
            "destroy" => "/:id"
          }.freeze
          private_constant :ROUTE_RESTFUL_URL_SUFFIXES

          attr_reader :fs

          attr_reader :inflector

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
            CLI::URL.call(url || ("/#{controller.join('/')}" + ROUTE_RESTFUL_URL_SUFFIXES.fetch(action)))
          end

          def route_http(action, http)
            result = (http ||= ROUTE_RESTFUL_HTTP_METHODS.fetch(action, ROUTE_DEFAULT_HTTP_METHOD)).downcase

            unless ROUTE_HTTP_METHODS.include?(result)
              raise ArgumentError.new("unknown HTTP method: `#{http}'")
            end

            result
          end
        end
      end
    end
  end
end
