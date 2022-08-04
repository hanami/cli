# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        require_relative "app/version"
        require_relative "app/install"
        require_relative "app/console"
        require_relative "app/server"
        require_relative "app/routes"
        require_relative "app/generate"
        require_relative "app/middlewares"
        # require_relative "app/db/create"
        # require_relative "app/db/create_migration"
        # require_relative "app/db/drop"
        # require_relative "app/db/migrate"
        # require_relative "app/db/setup"
        # require_relative "app/db/reset"
        # require_relative "app/db/rollback"
        # require_relative "app/db/sample_data"
        # require_relative "app/db/seed"
        # require_relative "app/db/structure/dump"
        # require_relative "app/db/version"

        def self.extended(base)
          base.module_eval do
            register "version", Commands::App::Version, aliases: ["v", "-v", "--version"]
            register "install", Commands::App::Install
            register "console", Commands::App::Console, aliases: ["c"]
            register "server", Commands::App::Server, aliases: ["s"]
            register "routes", Commands::App::Routes
            register "middlewares", Commands::App::Middlewares

            register "generate", aliases: ["g"] do |prefix|
              prefix.register "slice", Generate::Slice
              prefix.register "action", Generate::Action
            end
          end
        end
      end
    end
  end
end
