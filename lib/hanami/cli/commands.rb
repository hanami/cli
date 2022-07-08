# frozen_string_literal: true

module Hanami
  # TODO: move elsewhere
  def self.app?
    return true if File.exist?("config/app.rb")
  end

  module CLI
    module Commands
    end

    def self.register_commands!(within_hanami_app = Hanami.app?)
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
