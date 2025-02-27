# frozen_string_literal: true

require "dry/files"
require_relative "../constants"
require_relative "./ruby_class_file"
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
          def initialize(fs:, inflector:)
            @fs = fs
            @inflector = inflector
          end

          # @since 2.2.0
          # @api private
          def call(key:, namespace:, base_path:, relative_parent_class:, extra_namespace: nil, body: [])
            RubyClassFile.new(
              fs: fs,
              inflector: inflector,
              key: key,
              namespace: namespace,
              base_path: base_path,
              relative_parent_class: relative_parent_class,
              extra_namespace: extra_namespace,
              body: body,
            ).create
          end

          private

          # @since 2.2.0
          # @api private
          attr_reader :fs, :inflector
        end
      end
    end
  end
end
