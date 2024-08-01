# frozen_string_literal: true

require "erb"
require "dry/files"
require_relative "../constants"
require_relative "../../errors"

module Hanami
  module CLI
    module Generators
      module App
        # @since 2.2.0
        # @api private
        class RubyFileWriter
          # @since 2.2.0
          # @api private
          def initialize(
            fs:,
            inflector:,
            namespace:,
            key:,
            relative_parent_class:,
            extra_namespace: nil,
            body: []
          )
            @fs = fs
            @inflector = inflector
            @namespace = namespace
            @key = key
            @extra_namespace = extra_namespace&.downcase
            @relative_parent_class = relative_parent_class
            @body = body
            # raise_missing_slice_error_if_missing(slice) unless slice.app?
          end

          # @since 2.2.0
          # @api private
          def call
            fs.mkdir(directory)
            fs.write(path, file_contents)
          end

          private

          # @since 2.2.0
          # @api private
          attr_reader(
            :fs,
            :inflector,
            :namespace,
            :key,
            :extra_namespace,
            :relative_parent_class,
            :body,
          )

          # @since 2.2.0
          # @api private
          def file_contents
            class_definition(
              class_name: class_name,
              local_namespaces: local_namespaces,
            )
          end

          # @since 2.2.0
          # @api private
          def class_name
            key.split(KEY_SEPARATOR)[-1]
          end

          # @since 2.2.0
          # @api private
          def local_namespaces
            Array(extra_namespace) + key.split(KEY_SEPARATOR)[..-2]
          end

          # @since 2.2.0
          # @api private
          def directory
            @directory ||= if local_namespaces.any?
                             fs.join(source_path, local_namespaces)
                           else
                             source_path
                           end
          end

          def source_path
            if namespace == Hanami.app.namespace
              "app"
            else
              fs.join("slices", inflector.underscore(namespace))
            end
          end

          # @since 2.2.0
          # @api private
          def path
            fs.join(directory, "#{class_name}.rb")
          end

          # @since 2.2.0
          # @api private
          def class_definition(class_name:, local_namespaces:)
            container_module = normalize(namespace)

            modules = local_namespaces
              .map { normalize(_1) }
              .compact
              .prepend(container_module)

            parent_class = [container_module, relative_parent_class].join("::")

            RubyFileGenerator.class(
              normalize(class_name),
              parent_class: parent_class,
              modules: modules,
              header: ["# frozen_string_literal: true"],
              body: body
            )
          end

          # @since 2.2.0
          # @api private
          def normalize(name)
            inflector.camelize(name).gsub(/[^\p{Alnum}]/, "")
          end

          # @since 2.2.0
          # @api private
          def raise_missing_slice_error_if_missing(slice)
            # FIXME: Rename or remove?
            unless fs.directory?(slice.source_path)
              raise MissingSliceError.new(slice)
            end
          end
        end
      end
    end
  end
end
