# frozen_string_literal: true

require_relative "../constants"

module Hanami
  module CLI
    module Generators
      module App
        # @since x.x.x
        # @api private
        class RubyFile
          def initialize(
            fs:,
            inflector:,
            key:,
            namespace:,
            base_path:,
            extra_namespace: nil,
            auto_register: nil,
            body: [],
            **opts
          )
            @fs = fs
            @inflector = inflector
            @key = key
            @namespace = namespace
            @base_path = base_path
            @extra_namespace = extra_namespace&.downcase
            @auto_register = auto_register
            @body = body
          end

          # @since x.x.x
          # @api private
          def contents
            RubyFileGenerator.new(
              class_name: class_name,
              parent_class_name: parent_class_name,
              modules: modules,
              headers: headers,
              body: body
            ).call
          end

          # @since x.x.x
          # @api private
          def create
            fs.create(path, contents)
          end

          # @since x.x.x
          # @api private
          def write
            fs.write(path, contents)
          end

          # @since x.x.x
          # @api private
          def fully_qualified_name
            inflector.camelize(
              [namespace, extra_namespace, *key_parts].join("/"),
            )
          end

          private

          # @since x.x.x
          # @api private
          attr_reader(
            :fs,
            :inflector,
            :key,
            :base_path,
            :namespace,
            :extra_namespace,
            :auto_register,
            :body,
          )

          # @since x.x.x
          # @api private
          def local_namespaces
            Array(extra_namespace) + key_parts[..-2]
          end

          # @since x.x.x
          # @api private
          def namespace_modules
            [namespace, *local_namespaces]
              .map { normalize(_1) }
              .compact
          end

          # @since x.x.x
          # @api private
          def directory
            @directory ||= if local_namespaces.any?
                             fs.join(base_path, local_namespaces)
                           else
                             base_path
                           end
          end

          # @since x.x.x
          # @api private
          def path
            fs.join(directory, "#{key_parts.last}.rb")
          end

          # @since x.x.x
          # @api private
          def constant_name
            normalize(key_parts.last)
          end

          # @since x.x.x
          # @api private
          def headers
            [
              # Intentional ternary logic. Skip if nil, else 'true' or 'false'
              ("# auto_register: #{auto_register}" unless auto_register.nil?),
              "# frozen_string_literal: true",
            ].compact
          end

          # @since x.x.x
          # @api private
          def normalize(name)
            inflector.camelize(name).gsub(/[^\p{Alnum}]/, "")
          end

          # @since x.x.x
          # @api private
          def key_parts
            key.split(KEY_SEPARATOR)
          end
        end
      end
    end
  end
end
