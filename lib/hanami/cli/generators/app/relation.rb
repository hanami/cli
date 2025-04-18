# frozen_string_literal: true

require_relative "../constants"

module Hanami
  module CLI
    module Generators
      module App
        # @since 2.2.0
        # @api private
        class Relation
          # @since 2.2.0
          # @api private
          def initialize(fs:, inflector:, out: $stdout)
            @fs = fs
            @inflector = inflector
            @out = out
          end

          # @since 2.2.0
          # @api private
          def call(key:, namespace:, base_path:, gateway:)
            schema_name = key.split(KEY_SEPARATOR).last
            body_content = ["schema :#{schema_name}, infer: true"]

            body_content.prepend("gateway :#{gateway}") if gateway

            RubyFileWriter.new(
              fs: fs,
              inflector: inflector,
            ).call(
              namespace: namespace,
              key: key,
              base_path: base_path,
              extra_namespace: "Relations",
              partially_qualified_parent: "DB::Relation",
              body: body_content,
            )
          end

          private

          attr_reader :fs, :inflector, :out
        end
      end
    end
  end
end
