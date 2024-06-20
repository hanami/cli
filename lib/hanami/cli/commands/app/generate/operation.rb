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
          # @since x.x.x
          # @api private
          class Operation < App::Command
            argument :name, required: true, desc: "Operation name"
            option :slice, required: false, desc: "Slice name"

            example [
              %(books.add               (MyApp::Books::Add)),
              %(books.add --slice=admin (Admin::Books::Add)),
            ]
            attr_reader :generator
            private :generator

            # @since x.x.x
            # @api private
            def initialize(
              fs:, inflector:,
              generator: Generators::App::Operation.new(fs: fs, inflector: inflector),
              **opts
            )
              super(fs: fs, inflector: inflector, **opts)
              @generator = generator
            end

            # @since x.x.x
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
