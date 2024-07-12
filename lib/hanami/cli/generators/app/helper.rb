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
        class Helper
          # @since 2.2.0
          # @api private
          def initialize(fs, inflector, app_namespace, extra_namespace, local_parent_class, body, key, slice)
            @fs = fs
            @inflector = inflector
            @app_namespace = app_namespace
            @extra_namespace = extra_namespace&.downcase
            @local_parent_class = local_parent_class
            @body = body
            @key = key
            @slice = slice
            raise_missing_slice_error_if_missing(slice) if slice
          end

          def call
            fs.mkdir(directory)
            fs.write(path, file_contents)
          end

          def namespaced_key?
            key.split(KEY_SEPARATOR).length > 1
          end

          private

          attr_reader(
            :fs,
            :inflector,
            :app_namespace,
            :extra_namespace,
            :local_parent_class,
            :body,
            :key,
            :slice,
          )

          def class_name
            key.split(KEY_SEPARATOR)[-1]
          end

          def local_namespaces
            Array(extra_namespace) + key.split(KEY_SEPARATOR)[..-2]
          end

          def container_namespace
            slice || app_namespace
          end

          def directory
            base = if slice
                     fs.join("slices", slice)
                   else
                     fs.join("app")
                   end

            @directory ||= if local_namespaces.any?
                             fs.join(base, local_namespaces)
                           else
                             fs.join(base)
                           end
          end

          def path
            fs.join(directory, "#{class_name}.rb")
          end

          def file_contents
            class_definition(
              class_name: class_name,
              container_namespace: container_namespace,
              local_namespaces: local_namespaces,
            )
          end

          def class_definition(class_name:, container_namespace:, local_namespaces:)
            container_module = normalize(container_namespace)

            modules = local_namespaces
              .map { normalize(_1) }
              .compact
              .prepend(container_module)

            parent_class = [container_module, local_parent_class].join("::")

            RubyFileGenerator.class(
              normalize(class_name),
              parent_class: parent_class,
              modules: modules,
              header: ["# frozen_string_literal: true"],
              body: body
            )
          end

          def normalize(name)
            inflector.camelize(name).gsub(/[^\p{Alnum}]/, "")
          end

          def raise_missing_slice_error_if_missing(slice)
            if slice
              slice_directory = fs.join("slices", slice)
              raise MissingSliceError.new(slice) unless fs.directory?(slice_directory)
            end
          end
        end
      end
    end
  end
end
