# frozen_string_literal: true

require "dry/inflector"
require "dry/files"
require "shellwords"
require_relative "../../../naming"
require_relative "../../../errors"

module Hanami
  module CLI
    module Commands
      module App
        module Generate
          # @since 2.2.0
          # @api private
          class Command < App::Command
            option :slice, required: false, desc: "Slice name"

            attr_reader :generator
            private :generator

            attr_reader :inflector
            private :inflector

            # @since 2.2.0
            # @api private
            def initialize(
              fs:,
              inflector:,
              **
            )
              super
              @generator = generator_class.new(fs: fs, inflector: inflector, out: out)
            end

            def generator_class
              # Must be implemented by subclasses, with class that takes:
              # fs:, inflector:, out:
            end

            # @since 2.2.0
            # @api private
            def call(name:, slice: nil, **)
              if slice
                base_path = fs.join("slices", inflector.underscore(slice))
                raise MissingSliceError.new(slice) unless fs.exist?(base_path)

                generator.call(
                  key: name,
                  namespace: slice,
                  base_path: base_path,
                  **
                )
              else
                generator.call(
                  key: name,
                  namespace: app.namespace,
                  base_path: "app",
                  **
                )
              end
            end
          end
        end
      end
    end
  end
end
