# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module Gem
        require_relative "gem/version"
        require_relative "gem/new"

        def self.extended(base)
          base.module_eval do
            register "version", Version, aliases: ["v", "-v", "--version"]
            register "new", New
          end
        end
      end
    end
  end
end
