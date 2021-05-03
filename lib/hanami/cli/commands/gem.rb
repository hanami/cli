# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module Gem
        require_relative "gem/version"
        # FIXME: temporary disabled for Hanami v2.0.0.alpha2
        # require_relative "gem/new"

        def self.extended(base)
          base.module_eval do
            register "version", Version, aliases: ["v", "-v", "--version"]
            # FIXME: temporary disabled for Hanami v2.0.0.alpha2
            # register "new", New
          end
        end
      end
    end
  end
end
