# frozen_string_literal: true

require "dry/inflector"
require "dry/files"
require "shellwords"
module Hanami
  module CLI
    module Commands
      module App
        module Generate
          # @api private
          # @since 2.2.0
          class Component < App::Command
            argument :name, required: true, desc: "Component name"
            option :slice, required: false, desc: "Slice name"

            example [
              %(isbn_decoder               (MyApp::IsbnDecoder)),
              %(recommenders.fiction       (MyApp::Recommenders::Fiction)),
              %(isbn_decoder --slice=admin (Admin::IsbnDecoder)),
              %(Exporters::Complete::CSV   (MyApp::Exporters::Complete::CSV)),
            ]
            attr_reader :generator
            private :generator

            # @api private
            # @since 2.2.0
            def initialize(
              fs:, inflector:,
              generator: Generators::App::Component.new(fs: fs, inflector: inflector),
              **opts
            )
              @generator = generator
              super(fs: fs, inflector: inflector, **opts)
            end

            # @api private
            # @since 2.2.0
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
