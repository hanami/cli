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
            write_template_file(key:, base_path:)
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


          def write_template_file(base_path:, key:)
            folder_path = fs.join(base_path, "templates", key.split(KEY_SEPARATOR)[..-2])
            fs.mkdir_p(folder_path)
            file_path = fs.join(folder_path, template_with_format_ext(key.split(KEY_SEPARATOR).last, DEFAULT_FORMAT))
            fs.write(file_path, "<h1>Test::Views::Users::Index</h1>\n")
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
