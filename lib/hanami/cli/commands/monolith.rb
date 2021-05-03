# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module Monolith
        require_relative "monolith/version"
        # require_relative "monolith/install"
        # require_relative "monolith/generate"

        def self.extended(base)
          base.module_eval do
            register "version", Version, aliases: ["v", "-v", "--version"]
            # FIXME: temporary disabled for Hanami v2.0.0.alpha2
            # register "install", Install

            # FIXME: temporary disabled for Hanami v2.0.0.alpha2
            # register "generate", aliases: ["g"] do |prefix|
            #   prefix.register "slice", Generate::Slice
            #   prefix.register "action", Generate::Action
            # end
          end
        end
      end
    end
  end
end
