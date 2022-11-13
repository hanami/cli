# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module Gem
        def self.extended(base)
          base.module_eval do
            register "version", Commands::Gem::Version, aliases: ["v", "-v", "--version"]
            register "new", Commands::Gem::New
          end
        end
      end
    end
  end
end
