# frozen_string_literal: true

require "dry/inflector"
require "dry/files"
require "shellwords"
require_relative "../../../naming"
require_relative "../../../errors"
require 'byebug'

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
              # This has to be Pathname.pwd I think, otherwise we don't know how deeply we are nested
              # https://github.com/search?q=repo%3Adry-rb%2Fdry-files%20path%3A%2F%5Espec%5C%2Funit%5C%2Fdry%5C%2Ffiles%5C%2F%2F%20pwd&type=code
              # unless this links shows me I am wrong
              current_dir = Dir.pwd
              slices_dir = fs.join(app.root.to_s, "slices")
              puts "!!!!!"
              puts "!!!!!"
              puts "!!!!!"
              puts "!!!!!"
              puts "!!!!!"
              puts "current_dir: #{current_dir}"
              puts "slices_dir: #{slices_dir}"
              puts "!!!!!"
              puts "!!!!!"
              puts "!!!!!"
              puts "!!!!!"
              puts "!!!!!"
              return unless current_dir.start_with?(slices_dir)

              relative_path = current_dir.delete_prefix("#{slices_dir}/")
              slice_name = relative_path.split("/").first
              return unless app.slices.keys.include?(slice_name.to_sym)

              slice_name if app.slices[slice_name.to_sym]
            end

            # @since 2.2.0
            # @api private
            def call(name:, slice: nil, **opts)
              slice ||= detect_slice_from_pwd
              if slice
                base_path = fs.join("slices", inflector.underscore(slice))
                raise MissingSliceError.new(slice) unless fs.exist?(base_path) || slice == fs.pwd

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
