# frozen_string_literal: true

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
            @view_generator = Generators::App::View.new(
              fs: fs,
              inflector: inflector,
              out: out
            )
          end

          # @since 2.0.0
          # @api private
          def call(namespace:, key:, base_path:, url_path:, http_verb:, skip_view:, skip_route:)
            insert_route(namespace:, key:, base_path:, url_path:, http_verb:, skip_route:) unless skip_route

            generate_action(key:, namespace:, base_path:, include_placeholder_body: skip_view)

            generate_view(key:, namespace:, base_path:) unless skip_view
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

          attr_reader :fs, :inflector, :out, :view_generator

          def generate_action(key:, namespace:, base_path:, include_placeholder_body:)
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
                ("  response.body = self.class.name" if include_placeholder_body),
                "end"
              ].compact
            ).create
          end

          def generate_view(key:, namespace:, base_path:)
            *controller_names, view_name = key.split(KEY_SEPARATOR)

            view_directory = fs.join(base_path, "views", controller_names)

            if generate_view?(view_name, view_directory)
              view_generator.call(
                key: key,
                namespace: namespace,
                base_path: base_path,
              )
            end
          end

          def slice_matcher(slice)
            /slice[[:space:]]*:#{slice}/
          end

          def insert_route(key:, namespace:, base_path:, url_path:, http_verb:, skip_route:)
            *controller_names, action_name = key.split(KEY_SEPARATOR)

            if namespace == Hanami.app.namespace
              fs.inject_line_at_class_bottom(
                fs.join("config", "routes.rb"),
                "class Routes",
                route(controller_names, action_name, url_path, http_verb)
              )
            else
              fs.inject_line_at_block_bottom(
                fs.join("config", "routes.rb"),
                slice_matcher(namespace),
                route(controller_names, action_name, url_path, http_verb)
              )
            end
          end

          def route(controller, action, url, http)
            %(#{route_http(action, http)} "#{route_url(controller, action, url)}", to: "#{controller.join('.')}.#{action}")
          end

          # @api private
          # @since 2.1.0
          def generate_view?(view, directory)
            if rest_view?(view)
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
