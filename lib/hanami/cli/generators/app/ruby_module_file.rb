# frozen_string_literal: true

require_relative "../constants"

module Hanami
  module CLI
    module Generators
      module App
        # @since x.x.x
        # @api private
        class RubyModuleFile
          def initialize(
            fs:,
            inflector:,
            key:,
            namespace:,
            base_path:,
            extra_namespace: nil,
            auto_register: nil,
            body: []
          )
            @fs = fs
            @inflector = inflector
            @key = key
            @namespace = namespace
            @base_path = base_path
            # FIXME: consider removing extra_namespace
            # And also consider extracting helper to handle all common behavior with RubyClassFile
            @extra_namespace = extra_namespace&.downcase
            @auto_register = auto_register
            @body = body
          end

          # @since x.x.x
          # @api private
          def create
            fs.create(path, file_contents)
          end

          # @since x.x.x
          # @api private
          def write
            fs.write(path, file_contents)
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
            :namespace,
            :base_path,
            :extra_namespace,
            :auto_register,
            :body,
          )

          # @since x.x.x
          # @api private
          def file_contents
            module_definition(
              module_name: module_name,
              local_namespaces: local_namespaces,
            )
          end

          # @since x.x.x
          # @api private
          def module_name
            key_parts.last
          end

          # @since x.x.x
          # @api private
          def local_namespaces
            Array(extra_namespace) + key_parts[..-2]
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
            fs.join(directory, "#{module_name}.rb")
          end

          # @since x.x.x
          # @api private
          def module_definition(module_name:, local_namespaces:)
            container_module = normalize(namespace)

            modules = local_namespaces
              .map { normalize(_1) }
              .compact
              .prepend(container_module)
              .append(normalize(module_name))

            RubyFileGenerator.module(
              modules,
              header: headers,
              body: body
            )
          end

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
