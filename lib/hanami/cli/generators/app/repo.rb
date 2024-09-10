# frozen_string_literal: true

module Hanami
  module CLI
    module Generators
      module App
        # @since 2.2.0
        # @api private
        class Repo
          # @since 2.2.0
          # @api private
          def initialize(fs:, inflector:, out: $stdout)
            @fs = fs
            @inflector = inflector
            @out = out
          end

          # @since 2.2.0
          # @api private
          def call(key:, namespace:, base_path:)
            RubyFileWriter.new(
              fs: fs,
              inflector: inflector,
            ).call(
              key: key,
              namespace: namespace,
              base_path: base_path,
              extra_namespace: "Repos",
              relative_parent_class: "DB::Repo",
              body: [],
            )
          end

          private

          attr_reader :fs, :inflector, :out
        end
      end
    end
  end
end
