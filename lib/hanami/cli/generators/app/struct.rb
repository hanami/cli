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

          def extra_namespace
            "Structs"
          end

          def relative_parent_class
            "DB::Struct"
          end

          def body
            []
          end

          # @since 2.2.0
          # @api private
          def call(app_namespace, key, slice)
            Helper.new(
              fs: fs,
              inflector: inflector,
              app_namespace: app_namespace,
              extra_namespace: "Structs",
              local_parent_class: "DB::Struct",
              body: [],
              key: key,
              slice: slice,
            ).call
          end

          private

          attr_reader :fs, :inflector, :out
        end
      end
    end
  end
end
