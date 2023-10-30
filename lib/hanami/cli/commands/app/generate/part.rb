# frozen_string_literal: true

require "dry/inflector"
require "dry/files"
require "shellwords"

module Hanami
  module CLI
    module Commands
      module App
        module Generate
          # @since 2.1.0
          # @api private
          class Part < App::Command
            argument :name, required: true, desc: "Part name"
            option :slice, required: false, desc: "Slice name"

            example [
              %(book               (MyApp::Views::Parts::Book)),
              %(book --slice=admin (Admin::Views::Parts::Book)),
            ]
            attr_reader :generator
            private :generator

            # @since 2.0.0
            # @api private
            def initialize(
              fs: Hanami::CLI::Files.new,
              inflector: Dry::Inflector.new,
              generator: Generators::App::Part.new(fs: fs, inflector: inflector),
              **
            )
              @generator = generator
              super(fs: fs)
            end

            # @since 2.0.0
            # @api private
            def call(name:, slice: nil, **)
              slice = inflector.underscore(Shellwords.shellescape(slice)) if slice

              generator.call(app.namespace, name, slice)
            end
          end
        end
      end
    end
  end
end
