# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      # Commands made available when the `hanami` CLI is executed within an Hanami app.
      #
      # @api private
      # @since 2.0.0
      module App
        # @since 2.0.0
        # @api private
        def self.extended(base)
          base.module_eval do
            register "version", Commands::App::Version, aliases: ["v", "-v", "--version"]
            register "install", Commands::App::Install
            register "dev", Commands::App::Dev
            register "console", Commands::App::Console, aliases: ["c"]
            register "server", Commands::App::Server, aliases: ["s"]
            register "routes", Commands::App::Routes
            register "middleware", Commands::App::Middleware

            if Hanami.bundled?("hanami-assets")
              register "assets" do |prefix|
                prefix.register "compile", Assets::Compile
                prefix.register "watch", Assets::Watch
              end
            end

            if Hanami.bundled?("hanami-db")
              register "db" do |db|
                db.register "create", DB::Create
                db.register "drop", DB::Drop
                db.register "migrate", DB::Migrate
                db.register "structure dump", DB::Structure::Dump
                db.register "structure load", DB::Structure::Load
                db.register "seed", DB::Seed
                db.register "prepare", DB::Prepare
                db.register "version", DB::Version
              end
            end

            register "generate", aliases: ["g"] do |prefix|
              prefix.register "action", Generate::Action
              prefix.register "component", Generate::Component
              prefix.register "operation", Generate::Operation
              prefix.register "part", Generate::Part
              prefix.register "repo", Generate::Repo
              prefix.register "slice", Generate::Slice
              prefix.register "struct", Generate::Struct
              prefix.register "view", Generate::View
            end
          end
        end
      end
    end
  end
end
