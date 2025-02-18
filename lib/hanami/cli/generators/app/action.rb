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
          def initialize(fs:, inflector:, out: $stdout)
            @fs = fs
            @inflector = inflector
            @out = out
          end

          # @since 2.0.0
          # @api private
          def call(url_path, http, skip_view, skip_route, slice, namespace:, key:, base_path:)
            *controller, action = key.split(Commands::App::Command::ACTION_SEPARATOR)

            if slice

              unless skip_route
                fs.inject_line_at_block_bottom(
                  fs.join("config", "routes.rb"),
                  slice_matcher(slice),
                  route(controller, action, url_path, http)
                )
              end

              generate_files(controller, action, skip_view, namespace:, key:, base_path:)
            else
              base_path = "app"

              unless skip_route
                fs.inject_line_at_class_bottom(
                  fs.join("config", "routes.rb"),
                  "class Routes",
                  route(controller, action, url_path, http)
                )
              end

              generate_files(controller, action, skip_view, namespace:, key:, base_path:)
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

          attr_reader :fs, :inflector, :out

          # rubocop:disable Metrics/AbcSize
          def generate_files(controller, action, skip_view, namespace:, key:, base_path:)
            RubyClassFile.new(
              fs: fs,
              inflector: inflector,
              namespace: namespace,
              key: inflector.underscore(key),
              base_path: base_path,
              relative_parent_class: "Action",
              extra_namespace: "Actions",
              body: [
                "def handle(request, response)",
                ("  response.body = self.class.name" if skip_view),
                "end"
              ].compact
            ).create

            view = action
            view_directory = fs.join(base_path, "views", controller)

            if generate_view?(skip_view, view, view_directory)
              Generators::App::View.new(
                fs: fs,
                inflector: inflector,
                out: out
              ).call(
                key: key,
                namespace: namespace,
                base_path: base_path
              )
            end
          end

          def slice_matcher(slice)
            /slice[[:space:]]*:#{slice}/
          end

          def route(controller, action, url, http)
            %(#{route_http(action, http)} "#{route_url(controller, action, url)}", to: "#{controller.join('.')}.#{action}")
          end

          # @api private
          # @since 2.1.0
          def generate_view?(skip_view, view, directory)
            if skip_view
              false
            elsif rest_view?(view)
              generate_restful_view?(view, directory)
            else
              true
            end
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
