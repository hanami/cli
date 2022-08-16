# frozen_string_literal: true

require "hanami"

module Hanami
  module CLI
    module Commands
    end

    def self.register_commands!(within_hanami_app = !!Hanami.app_path)
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
