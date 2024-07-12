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
            argument :name, required: true, desc: "Name"
            option :slice, required: false, desc: "Slice name"

            attr_reader :generator
            private :generator

            # @since 2.2.0
            # @api private
            def initialize(
              fs:,
              inflector:,
              generator_class: nil,
              **opts
            )
              raise "Provide a generator_class (that takes fs: and inflector:)" if generator_class.nil?

              super(fs: fs, inflector: inflector, **opts)
              @generator = generator_class.new(fs: fs, inflector: inflector, out: out)
            end

            # @since 2.2.0
            # @api private
            def call(name:, slice: nil, **)
              normalized_slice = inflector.underscore(Shellwords.shellescape(slice)) if slice
              generator.call(app.namespace, name, normalized_slice)
            end
          end
        end
      end
    end
  end
end
