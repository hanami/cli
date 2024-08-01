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
              generator.call(
                key: name,
                namespace: namespace(slice),
                base_path: base_path(slice)
              )
            end

            private

            def base_path(slice)
              if slice
                fs.join("slices", inflector.underscore(slice))
              else
                "app"
              end
            end

            def namespace(slice)
              if slice
                inflector.camelize(slice).gsub(/[^\p{Alnum}]/, "")
              else
                app.namespace
              end
            end
          end
        end
      end
    end
  end
end
