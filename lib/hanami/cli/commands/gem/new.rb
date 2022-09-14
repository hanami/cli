# frozen_string_literal: true

require "hanami/cli/command"
require "hanami/cli/bundler"
require "hanami/cli/git"
require "hanami/cli/command_line"
require "hanami/cli/generators/gem/app"
require "hanami/cli/files"
require "dry/inflector"

module Hanami
  module CLI
    module Commands
      module Gem
        class New < Command
          SKIP_INSTALL_DEFAULT = false
          SKIP_GIT_DEFAULT = false
          private_constant :SKIP_GIT_DEFAULT
          private_constant :SKIP_INSTALL_DEFAULT

          desc "Generate a new Hanami app"

          argument :app, required: true, desc: "App name"

          option :skip_install, type: :boolean, required: false,
                                default: SKIP_INSTALL_DEFAULT,
                                desc: "Skip app installation (Bundler, third-party Hanami plugins)"

          example [
            "bookshelf                # Generate a new Hanami app in `bookshelf/' directory, using `Bookshelf' namespace", # rubocop:disable Layout/LineLength
            "bookshelf --skip-install # Generate a new Hanami app, but it skips Hanami installation"
          ]

          option :skip_git, type: :boolean, required: false,
                            default: SKIP_GIT_DEFAULT, desc: "Skip git init"

          # rubocop:disable Metrics/ParameterLists
          def initialize(
            fs: Hanami::CLI::Files.new,
            inflector: Dry::Inflector.new,
            bundler: CLI::Bundler.new(fs: fs),
            command_line: CLI::CommandLine.new(bundler: bundler),
            git: CLI::Git.new,
            generator: Generators::Gem::App.new(fs: fs, inflector: inflector, command_line: command_line),
            **other
          )
            @bundler = bundler
            @git = git
            @command_line = command_line
            @generator = generator
            super(fs: fs, inflector: inflector, **other)
          end
          # rubocop:enable Metrics/ParameterLists

          def call(app:, skip_install: SKIP_INSTALL_DEFAULT, skip_git: SKIP_GIT_DEFAULT, **)
            app = inflector.underscore(app)

            fs.mkdir(app)
            fs.chdir(app) do
              generator.call(app) do
                if skip_install
                  out.puts "Skipping installation, please enter `#{app}' directory and run `bundle exec hanami install'"
                else
                  out.puts "Running Bundler install..."
                  bundler.install!
                  out.puts "Running Hanami install..."
                  run_install_commmand!
                end

                git.init! unless skip_git
              end
            end
          end

          private

          attr_reader :bundler
          attr_reader :git
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
