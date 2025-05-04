# frozen_string_literal: true

require "dry/inflector"
require "dry/files"
require "shellwords"
require_relative "../../../naming"
require_relative "../../../errors"
require "pry"

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

            def initialize(fs:, inflector:, out:, **)
              super
              @generator = generator_class.new(fs:, inflector:, out:)
            end

            # @since 2.2.0
            # @api private
            def generator_class
              # Must be implemented by subclasses, with initialize method that takes:
              # fs:, inflector:, out:
            end

            def detect_slice_from_pwd
              current_dir = Pathname.pwd
              slices_dir = app.root.join("slices")
              return unless current_dir.to_s.start_with?(slices_dir.to_s)

              relative_path = current_dir.relative_path_from(slices_dir)
              slice_name = relative_path.to_s.split("/").first
              return unless app.slices.keys.include?(slice_name.to_sym)

              slice_name if app.slices[slice_name.to_sym]
            end

            # @since 2.2.0
            # @api private
            def call(name:, slice: nil, **opts)
              slice ||= detect_slice_from_pwd
              if slice
                base_path = fs.join("slices", inflector.underscore(slice))
                raise MissingSliceError.new(slice) unless fs.exist?(base_path)

                generator.call(
                  key: name,
                  namespace: slice,
                  base_path: base_path,
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
          end
        end
      end
    end
  end
end
