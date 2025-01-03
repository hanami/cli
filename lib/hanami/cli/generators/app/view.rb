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
          DEFAULT_FORMAT = "html"
          private_constant :DEFAULT_FORMAT

          TEMPLATES_FOLDER = "templates"
          private_constant :TEMPLATES_FOLDER

          # @since 2.0.0
          # @api private
          def initialize(fs:, inflector:, out: $stdout)
            @fs = fs
            @inflector = inflector
            @out = out
          end

          # @since 2.0.0
          # @api private
          def call(key:, namespace:, base_path:)
            view_class = view_class_file(key:, namespace:, base_path:)
            view_class.create
            view_class_name = view_class.fully_qualified_name
            write_template_file(key:, namespace:, base_path:, view_class_name:)
          end

          private

          attr_reader :fs, :inflector, :out

          def view_class_file(key:, namespace:, base_path:)
            RubyClassFile.new(
              fs: fs,
              inflector: inflector,
              namespace: namespace,
              key: inflector.underscore(key),
              base_path: base_path,
              relative_parent_class: "View",
              extra_namespace: "Views",
            )
          end

          def write_template_file(key:, namespace:, base_path:, view_class_name:)
            key_parts = key.split(KEY_SEPARATOR)
            class_name_from_key = key_parts.pop
            module_names_from_key = key_parts # Now that the class name has popped off

            file_path = fs.join(
              base_path,
              TEMPLATES_FOLDER,
              module_names_from_key,
              template_file_name(class_name_from_key, DEFAULT_FORMAT),
            )
            body = "<h1>#{view_class_name}</h1>\n"
            fs.write(file_path, body)
          end

          def template_file_name(name, format)
            ext =
              case format.to_sym
              when :html
                ".html.erb"
              else
                ".erb"
              end

            "#{name}#{ext}"
          end
        end
      end
    end
  end
end
