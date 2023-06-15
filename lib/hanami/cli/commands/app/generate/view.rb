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
          # @since 2.0.0
          # @api private
          class View < App::Command
            # TODO: make this configurable
            DEFAULT_FORMAT = "html"
            private_constant :DEFAULT_FORMAT

            # TODO: make engine configurable

            argument :name, required: true, desc: "View name"
            option :slice, required: false, desc: "Slice name"

            # rubocop:disable Layout/LineLength
            example [
              %(books.index               (MyApp::Actions::Books::Index)),
              %(books.index --slice=admin (Admin::Actions::Books::Index)),
            ]
            # rubocop:enable Layout/LineLength

            attr_reader :generator
            private :generator

            # @since 2.0.0
            # @api private
            def initialize(
              fs: Hanami::CLI::Files.new,
              inflector: Dry::Inflector.new,
              generator: Generators::App::View.new(fs: fs, inflector: inflector),
              **
            )
              @generator = generator
              super(fs: fs)
            end

            # rubocop:disable Metrics/ParameterLists

            # @since 2.0.0
            # @api private
            def call(name:, format: DEFAULT_FORMAT, slice: nil, **)
              slice = inflector.underscore(Shellwords.shellescape(slice)) if slice

              generator.call(app.namespace, name, format, slice)
            end

            # rubocop:enable Metrics/ParameterLists
          end
        end
      end
    end
  end
end
