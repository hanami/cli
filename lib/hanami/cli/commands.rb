# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
    end

    def self.register_commands!
      require_relative "commands/gem"

      extend(Commands::Gem)
    end
  end
end
