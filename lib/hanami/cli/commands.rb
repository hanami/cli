# frozen_string_literal: true

require "hanami/app_detector"

module Hanami
  module CLI
    def self.within_hanami_app?
      Hanami::AppDetector.new.() || false
    end

    module Commands
    end

    def self.register_commands!(within_hanami_app = Hanami::CLI.within_hanami_app?)
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
