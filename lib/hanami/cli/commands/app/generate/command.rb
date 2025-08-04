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

            def detect_slice_from_cwd
              slices_by_root = app.slices.with_nested.each.to_h { |slice| [slice.root.to_s, slice] }
              slices_by_root[fs.pwd]
              # # This has to be Pathname.pwd I think, otherwise we don't know how deeply we are nested
              # # https://github.com/search?q=repo%3Adry-rb%2Fdry-files%20path%3A%2F%5Espec%5C%2Funit%5C%2Fdry%5C%2Ffiles%5C%2F%2F%20pwd&type=code
              # # unless this links shows me I am wrong
              # current_dir = Dir.pwd
              # slices_dir = fs.join(app.root.to_s, "slices")
              # return unless current_dir.start_with?(slices_dir)
              #
              # relative_path = current_dir.delete_prefix("#{slices_dir}/")
              # slice_name = relative_path.split("/").first
              # return unless app.slices.keys.include?(slice_name.to_sym)
              #
              # slices_by_root = app.slices.with_nested.each.to_h { |slice| [slice.root, slice] }
              # slices_by_root[current_dir]
              # # slice_name if slices_by_root[current_dir.to_sym]
              # slice_name if slices_by_root[current_dir.to_sym]
            end

            # @since 2.2.0
            # @api private
            def call(name:, slice: nil, **opts)
              slice ||= detect_slice_from_cwd
              if slice
                slice_root =
                  if slice.respond_to?(:root)
                    slice.root
                  else
                    # TODO: Could be expanded to expect nested slices in command args
                    # like `--slice foo/bar/baz`. This would require us to take a different approach
                    # to determining their root. For the sake of this feature first version, we
                    # implement more simplistic top-level-only slice support when passing strings.
                    slices_dir = fs.join(app.root.to_s, "slices")
                    fs.join(slices_dir, inflector.underscore(slice))
                  end
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
          end
        end
      end
    end
  end
end
