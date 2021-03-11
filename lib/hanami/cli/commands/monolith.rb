# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module Monolith
        require_relative "monolith/version"
        require_relative "monolith/install"

        def self.extended(base)
          base.module_eval do
            register "version", Version, aliases: ["v", "-v", "--version"]
            register "install", Install
          end
        end
      end
    end
  end
end
