# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module Monolith
        require_relative "monolith/version"
        require_relative "monolith/install"
        require_relative "monolith/generate"

        def self.extended(base)
          base.module_eval do
            register "version", Version, aliases: ["v", "-v", "--version"]
            register "install", Install

            register "generate", aliases: ["g"] do |prefix|
              prefix.register "slice", Generate::Slice
            end
          end
        end
      end
    end
  end
end
