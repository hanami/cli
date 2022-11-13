# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        def self.extended(base)
          base.module_eval do
            register "version", Commands::App::Version, aliases: ["v", "-v", "--version"]
            register "install", Commands::App::Install
            register "console", Commands::App::Console, aliases: ["c"]
            register "server", Commands::App::Server, aliases: ["s"]
            register "routes", Commands::App::Routes
            register "middleware", Commands::App::Middleware

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
