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
          def call(app_namespace, key, slice)
            RubyFileWriter.new(
              fs: fs,
              inflector: inflector,
              app_namespace: app_namespace,
              key: key,
              slice: slice,
              extra_namespace: "Relations",
              relative_parent_class: "DB::Relation",
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
