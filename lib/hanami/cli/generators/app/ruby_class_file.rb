# frozen_string_literal: true

require_relative "../constants"

module Hanami
  module CLI
    module Generators
      module App
        # @since 2.2.2
        # @api private
        class RubyClassFile
          def initialize(
            fs:,
            inflector:,
            key:,
            namespace:,
            base_path:,
            extra_namespace: nil,
            partially_qualified_parent: nil,
            fully_qualified_parent: nil,
            auto_register: nil,
            body: []
          )
            if partially_qualified_parent && fully_qualified_parent
              raise "Must provide only one of partially_qualified_parent or fully_qualified_parent"
            end

            @fs = fs
            @inflector = inflector
            @key = key
            @namespace = namespace
            @base_path = base_path
            @extra_namespace = extra_namespace&.downcase
            @partially_qualified_parent = partially_qualified_parent
            @fully_qualified_parent = fully_qualified_parent
            @auto_register = auto_register
            @body = body
          end

          # @since 2.2.2
          # @api private
          def create
            fs.create(path, file_contents)
          end

          # @since 2.2.2
          # @api private
          def write
            fs.write(path, file_contents)
          end

          # @since 2.2.2
          # @api private
          def fully_qualified_name
            inflector.camelize(
              [namespace, extra_namespace, *key_parts].join("/"),
            )
          end

          private

          # @since 2.2.2
          # @api private
          attr_reader(
            :fs,
            :inflector,
            :key,
            :namespace,
            :base_path,
            :extra_namespace,
            :partially_qualified_parent,
            :fully_qualified_parent,
            :auto_register,
            :body,
          )

          # @since 2.2.2
          # @api private
          def file_contents
            class_definition(
              class_name: class_name,
              local_namespaces: local_namespaces,
            )
          end

          # @since 2.2.2
          # @api private
          def class_name
            key_parts.last
          end

          # @since 2.2.2
          # @api private
          def local_namespaces
            Array(extra_namespace) + key_parts[..-2]
          end

          # @since 2.2.2
          # @api private
          def directory
            @directory ||= if local_namespaces.any?
                             fs.join(base_path, local_namespaces)
                           else
                             base_path
                           end
          end

          # @since 2.2.2
          # @api private
          def path
            fs.join(directory, "#{class_name}.rb")
          end

          # @since 2.2.2
          # @api private
          def class_definition(class_name:, local_namespaces:)
            container_module = normalize(namespace)

            modules = local_namespaces
              .map { normalize(_1) }
              .compact
              .prepend(container_module)

            parent_class = if partially_qualified_parent
              [container_module, partially_qualified_parent].join("::")
            else
              fully_qualified_parent
            end

            RubyFileGenerator.class(
              normalize(class_name),
              parent_class: parent_class,
              modules: modules,
              header: headers,
              body: body
            )
          end

          def headers
            [
              # Intentionally ternary logic. Skip if nil, else 'true' or 'false'
              ("# auto_register: #{auto_register}" unless auto_register.nil?),
              "# frozen_string_literal: true",
            ].compact
          end

          # @since 2.2.2
          # @api private
          def normalize(name)
            inflector.camelize(name).gsub(/[^\p{Alnum}]/, "")
          end

          # @since 2.2.2
          # @api private
          def key_parts
            key.split(KEY_SEPARATOR)
          end
        end
      end
    end
  end
end
