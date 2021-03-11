# frozen_string_literal: true

module Hanami
  # TODO: move elsewhere
  def self.architecture
    return :monolith if File.exist?("config/application.rb")
  end

  module CLI
    module Commands
    end

    def self.register_commands!(architecture = Hanami.architecture)
      commands = case architecture
                 when :monolith
                   require_relative "commands/monolith"
                   Commands::Monolith
                 else
                   require_relative "commands/gem"
                   Commands::Gem
                 end

      extend(commands)
    end
  end
end
