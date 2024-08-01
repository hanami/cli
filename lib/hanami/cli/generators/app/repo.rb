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
          def call(namespace, key, slice)
            RubyFileWriter.new(
              fs: fs,
              inflector: inflector,
              namespace: namespace,
              key: key,
              slice: slice,
              extra_namespace: "Repos",
              relative_parent_class: "DB::Repo",
              body: [],
            ).call
          end

          private

          attr_reader :fs, :inflector, :out
        end
      end
    end
  end
end
