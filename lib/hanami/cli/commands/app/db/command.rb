# frozen_string_literal: true

require "hanami/env"
require_relative "utils/database"
require_relative "../../../files"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # Base class for `hanami` CLI commands intended to be executed within an existing Hanami
          # app.
          #
          # @since 2.2.0
          # @api private
          class Command < App::Command
            attr_reader :database

            def initialize(**)
              super

              # TODO: make plural (for slices)
              @database = Utils::Database[app]
            end
          end
        end
      end
    end
  end
end
