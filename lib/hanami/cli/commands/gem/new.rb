# frozen_string_literal: true

require "hanami/cli/command"
require "hanami/cli/bundler"
require "hanami/cli/command_line"
require "hanami/cli/generators/gem/application"
require "dry/files"
require "dry/inflector"

module Hanami
  module CLI
    module Commands
      module Gem
        class New < Command
          argument :app, required: true, desc: "Application name"

          # rubocop:disable Metrics/ParameterLists
          def initialize(
            fs: Dry::Files.new,
            inflector: Dry::Inflector.new,
            bundler: CLI::Bundler.new(fs: fs),
            command_line: CLI::CommandLine.new(bundler: bundler),
            generator: Generators::Gem::Application.new(fs: fs, inflector: inflector, command_line: command_line),
            **other
          )
            @bundler = bundler
            @command_line = command_line
            @generator = generator
            super(fs: fs, inflector: inflector, **other)
          end
          # rubocop:enable Metrics/ParameterLists

          def call(app:, **)
            app = inflector.underscore(app)

            fs.mkdir(app)
            fs.chdir(app) do
              generator.call(app) do
                bundler.install!
                run_install_commmand!
              end
            end
          end

          private

          attr_reader :bundler
          attr_reader :command_line
          attr_reader :generator

          def run_install_commmand!
            command_line.call("hanami install").tap do |result|
              raise "hanami install failed\n\n\n#{result.err.inspect}" unless result.successful?
            end
          end
        end
      end
    end
  end
end
