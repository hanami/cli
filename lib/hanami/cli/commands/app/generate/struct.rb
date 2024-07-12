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
          class Struct < Command
            argument :name, required: true, desc: "Struct name"
            option :slice, required: false, desc: "Slice name"

            example [
              %(books.add               (MyApp::Books::Add)),
              %(books.add --slice=admin (Admin::Books::Add)),
            ]
            attr_reader :generator
            private :generator

            # @since 2.2.0
            # @api private
            def initialize(
              generator_class: nil,
              **opts
            )
              super
            end

            # @since 2.2.0
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
