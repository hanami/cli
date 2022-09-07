# frozen_string_literal: true

require "hanami/cli/command"
require "hanami/cli/bundler"
require "hanami/cli/command_line"
require "hanami/cli/generators/gem/app"
require "dry/files"
require "dry/inflector"

module Hanami
  module CLI
    module Commands
      module Gem
        class New < Command
          SKIP_BUNDLE_DEFAULT = false
          private_constant :SKIP_BUNDLE_DEFAULT

          ROOT_PATH = "/"
          private_constant :ROOT_PATH

          argument :app_path, required: true, desc: "App path"

          option :skip_bundle, type: :boolean, required: false,
                               default: SKIP_BUNDLE_DEFAULT, desc: "Skip bundle install"

          # rubocop:disable Metrics/ParameterLists
          def initialize(
            fs: Dry::Files.new,
            inflector: Dry::Inflector.new,
            bundler: CLI::Bundler.new(fs: fs),
            command_line: CLI::CommandLine.new(bundler: bundler),
            generator: Generators::Gem::App.new(fs: fs, inflector: inflector, command_line: command_line),
            **other
          )
            @bundler = bundler
            @command_line = command_line
            @generator = generator
            super(fs: fs, inflector: inflector, **other)
          end
          # rubocop:enable Metrics/ParameterLists

          def call(app_path:, skip_bundle: SKIP_BUNDLE_DEFAULT, **)
            raise ArgumentError, <<~MSG if app_path == ROOT_PATH
              System's root directory is not allowed as the application path
            MSG

            fs.mkdir(app_path)
            fs.chdir(app_path) do
              app_name = File.basename(File.expand_path(app_path))
              generator.call(app_name) do
                unless skip_bundle
                  bundler.install!
                  run_install_commmand!
                end
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
