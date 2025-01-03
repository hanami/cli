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
            write_view_file(key:, namespace:, base_path:)
            write_template_file(key:, namespace:, base_path:)
          end

          private

          attr_reader :fs, :inflector, :out

          def write_view_file(key:, namespace:, base_path:)
            RubyFileWriter.new(
              fs: fs,
              inflector: inflector,
            ).call(
              namespace: namespace,
              key: inflector.underscore(key),
              base_path: base_path,
              relative_parent_class: "View",
              extra_namespace: "Views",
            )
          end


          def write_template_file(key:, namespace:, base_path:)
            key_parts = key.split(KEY_SEPARATOR)
            folder_path = fs.join(base_path, "templates", key_parts[..-2])
            file_path = fs.join(folder_path, template_with_format_ext(key_parts.last, DEFAULT_FORMAT))
            view_class_name = inflector.camelize([namespace, "Views", *key_parts].join("/"))
            body = "<h1>#{view_class_name}</h1>\n"
            fs.write(file_path, body)
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
        end
      end
    end
  end
end
