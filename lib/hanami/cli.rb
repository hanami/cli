# frozen_string_literal: true

require "dry/cli"

module Hanami
  module CLI
    require_relative "cli/version"
    require_relative "cli/error"
    require_relative "cli/bundler"
    require_relative "cli/commands"

    extend Dry::CLI::Registry

    register_commands!
  end
end
