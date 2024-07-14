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
        class Operation
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
            RubyFileWriter.new(
              fs: fs,
              inflector: inflector,
              app_namespace: app_namespace,
              key: key,
              slice: slice,
              relative_parent_class: "Operation",
              class_body: ["def call", "end"],
            ).call

            unless key.match?(KEY_SEPARATOR)
              out.puts(
                "  Note: We generated a top-level operation. " \
                "To generate into a directory, add a namespace: `my_namespace.add_book`"
              )
            end
          end

          private

          attr_reader :fs, :inflector, :out
        end
      end
    end
  end
end
