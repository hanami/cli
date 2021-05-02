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

            register "console", Commands::Console

            register "db create", Commands::DB::Create
            register "db create_migration", Commands::DB::CreateMigration
            register "db drop", Commands::DB::Drop
            register "db migrate", Commands::DB::Migrate
            register "db setup", Commands::DB::Setup
            register "db reset", Commands::DB::Reset
            register "db rollback", Commands::DB::Rollback
            register "db sample_data", Commands::DB::SampleData
            register "db seed", Commands::DB::Seed
            register "db structure dump", Commands::DB::Structure::Dump
            register "db version", Commands::DB::Version
          end
        end
      end
    end
  end
end
