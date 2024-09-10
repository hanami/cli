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

            # @since 2.2.0
            # @api private
            def initialize(
              fs:,
              inflector:,
              **opts
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
                generator.call(
                  key: name,
                  namespace: slice,
                  base_path: fs.join("slices", inflector.underscore(slice))
                )
              else
                generator.call(
                  key: name,
                  namespace: app.namespace,
                  base_path: "app"
                )
              end
            end
          end
        end
      end
    end
  end
end
