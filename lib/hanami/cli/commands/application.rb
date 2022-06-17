# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module Application
        require_relative "application/version"
        require_relative "application/install"
        require_relative "application/console"
        # require_relative "application/generate"
        # require_relative "application/db/create"
        # require_relative "application/db/create_migration"
        # require_relative "application/db/drop"
        # require_relative "application/db/migrate"
        # require_relative "application/db/setup"
        # require_relative "application/db/reset"
        # require_relative "application/db/rollback"
        # require_relative "application/db/sample_data"
        # require_relative "application/db/seed"
        # require_relative "application/db/structure/dump"
        # require_relative "application/db/version"

        def self.extended(base)
          base.module_eval do
            register "version", Commands::Application::Version, aliases: ["v", "-v", "--version"]
            register "install", Commands::Application::Install
            register "console", Commands::Application::Console, aliases: ["c"]

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
