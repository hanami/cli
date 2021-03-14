# frozen_string_literal: true

require "hanami/cli/command"
require "hanami/cli/bundler"
require "hanami/cli/command_line"
require "hanami/cli/generators/application"
require "dry/cli/utils/files"

module Hanami
  module CLI
    module Commands
      module Gem
        class New < Command
          ARCHITECTURES = %w[monolith micro].freeze
          private_constant :ARCHITECTURES

          DEFAULT_ARCHITECTURE = ARCHITECTURES.first
          private_constant :DEFAULT_ARCHITECTURE

          argument :app, required: true, desc: "The application name"

          option :architecture, alias: "arch", default: DEFAULT_ARCHITECTURE,
                                values: ARCHITECTURES, desc: "The architecture"

          def initialize(fs: Dry::CLI::Utils::Files.new, bundler: CLI::Bundler.new(fs: fs),
                         command_line: CLI::CommandLine.new(bundler: bundler), **other)
            @bundler = bundler
            @command_line = command_line
            super(fs: fs, **other)
          end

          def call(app:, architecture: DEFAULT_ARCHITECTURE, **)
            app = inflector.underscore(app)

            out.puts "generating #{app}"

            fs.mkdir(app)
            fs.chdir(app) do
              generator(architecture).call(app)
              bundler.install!
              run_install_commmand!
            end
          end

          private

          attr_reader :bundler
          attr_reader :command_line

          def generator(architecture)
            unless ARCHITECTURES.include?(architecture)
              raise ArgumentError.new("unknown architecture `#{architecture}'")
            end

            Generators::Application[architecture, fs, inflector]
          end

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
