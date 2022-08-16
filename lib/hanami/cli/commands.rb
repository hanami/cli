# frozen_string_literal: true

require "hanami"

module Hanami
  module CLI
    # Returns true if the CLI is being called from inside an Hanami app.
    #
    # This is typically used to determine whether to register commands that are applicable either
    # inside or outside an app.
    #
    # @api public
    # @since 2.0.0
    def self.within_hanami_app?
      !!Hanami.app_path
    end

    module Commands
    end

    # @api private
    def self.register_commands!(within_hanami_app = within_hanami_app?)
      commands = if within_hanami_app
                   require_relative "commands/app"
                   Commands::App
                 else
                   require_relative "commands/gem"
                   Commands::Gem
                 end

      extend(commands)
    end
  end
end
