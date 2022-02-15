# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module Monolith
        require_relative "monolith/version"
        # require_relative "monolith/install"
        # require_relative "monolith/generate"
        require_relative "monolith/install"
        require_relative "monolith/generate"
        require_relative "monolith/console"
        require_relative "monolith/server"
        require_relative "monolith/db/create"
        require_relative "monolith/db/create_migration"
        require_relative "monolith/db/drop"
        require_relative "monolith/db/migrate"
        require_relative "monolith/db/setup"
        require_relative "monolith/db/reset"
        require_relative "monolith/db/rollback"
        require_relative "monolith/db/sample_data"
        require_relative "monolith/db/seed"
        require_relative "monolith/db/structure/dump"
        require_relative "monolith/db/version"

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

            register "console", Commands::Monolith::Console

            register "server", Commands::Monolith::Server

            register "db create", Commands::Monolith::DB::Create
            register "db create_migration", Commands::Monolith::DB::CreateMigration
            register "db drop", Commands::Monolith::DB::Drop
            register "db migrate", Commands::Monolith::DB::Migrate
            register "db setup", Commands::Monolith::DB::Setup
            register "db reset", Commands::Monolith::DB::Reset
            register "db rollback", Commands::Monolith::DB::Rollback
            register "db sample_data", Commands::Monolith::DB::SampleData
            register "db seed", Commands::Monolith::DB::Seed
            register "db structure dump", Commands::Monolith::DB::Structure::Dump
            register "db version", Commands::Monolith::DB::Version
          end
        end
      end
    end
  end
end
