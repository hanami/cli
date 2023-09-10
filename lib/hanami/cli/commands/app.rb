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
            register "console", Commands::App::Console, aliases: ["c"]
            register "server", Commands::App::Server, aliases: ["s"]
            register "routes", Commands::App::Routes
            register "middleware", Commands::App::Middleware
            register "assets" do |prefix|
              prefix.register "watch", Assets::Watch
            end

            register "generate", aliases: ["g"] do |prefix|
              prefix.register "slice", Generate::Slice
              prefix.register "action", Generate::Action
              prefix.register "view", Generate::View
            end
          end
        end
      end
    end
  end
end
