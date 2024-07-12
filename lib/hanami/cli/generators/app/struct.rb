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
        class Struct
          # @since 2.2.0
          # @api private
          def initialize(fs:, inflector:, out: $stdout)
            @fs = fs
            @inflector = inflector
            @out = out
          end

          # @since 2.2.0
          # @api private
          def call(app_namespace, key, slice)
            struct_name = key.split(KEY_SEPARATOR)[-1]
            local_namespaces = ["structs"] + key.split(KEY_SEPARATOR)[..-2]
            container_namespace = slice || app_namespace

            raise_missing_slice_error_if_missing(slice) if slice

            directory = directory(slice, local_namespaces: local_namespaces)
            path = fs.join(directory, "#{struct_name}.rb")
            fs.mkdir(directory)

            file_contents = class_definition(
              struct_name: struct_name,
              container_namespace: container_namespace,
              local_namespaces: local_namespaces,
            )
            fs.write(path, file_contents)
          end

          private

          attr_reader :fs, :inflector, :out

          def directory(slice = nil, local_namespaces:)
            base = if slice
                     fs.join("slices", slice)
                   else
                     fs.join("app")
                   end

            if local_namespaces.any?
              fs.join(base, local_namespaces)
            else
              fs.join(base)
            end
          end

          def class_definition(struct_name:, container_namespace:, local_namespaces:)
            container_module = normalize(container_namespace)

            modules = local_namespaces
              .map { normalize(_1) }
              .compact
              .prepend(container_module)

            parent_class = [container_module, "DB", "Struct"].join("::")

            RubyFileGenerator.class(
              normalize(struct_name),
              parent_class: parent_class,
              modules: modules,
              header: ["# frozen_string_literal: true"],
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
