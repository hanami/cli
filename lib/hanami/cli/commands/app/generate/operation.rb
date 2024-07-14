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
          class Operation < Generate::Command
            example [
              %(books.add               (MyApp::Books::Add)),
              %(books.add --slice=admin (Admin::Books::Add)),
            ]

            # @since 2.2.0
            # @api private
            def initialize(**opts)
              super(generator_class: Generators::App::Operation, **opts)
            end
          end
        end
      end
    end
  end
end
