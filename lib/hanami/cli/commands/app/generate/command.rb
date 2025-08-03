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
            def call(name:, slice: nil, **opts)
              slice ||= detect_slice_from_cwd

              if slice
                slice_root = slice.root
                raise MissingSliceError.new(slice) unless fs.exist?(slice_root)

                generator.call(
                  key: name,
                  namespace: slice,
                  base_path: slice_root,
                  **opts,
                )
              else
                generator.call(
                  key: name,
                  namespace: app.namespace,
                  base_path: "app",
                  **opts,
                )
              end
            end

            private

            def detect_slice_from_cwd
              slices_by_root = app.slices.with_nested.each.to_h { |slice| [slice.root.to_s, slice] }
              slices_by_root[fs.pwd]
            end
          end
        end
      end
    end
  end
end
