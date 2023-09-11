# frozen_string_literal: true

require "dry/inflector"
require_relative "../../errors"

module Hanami
  module CLI
    module Commands
      module Gem
        # @since 2.0.0
        # @api private
        class New < Command
          # @since 2.0.0
          # @api private
          SKIP_INSTALL_DEFAULT = false
          private_constant :SKIP_INSTALL_DEFAULT

          # @since 2.1.0
          # @api private
          SKIP_ASSETS_DEFAULT = false
          private_constant :SKIP_ASSETS_DEFAULT

          desc "Generate a new Hanami app"

          # @since 2.0.0
          # @api private
          argument :app, required: true, desc: "App name"

          # @since 2.0.0
          # @api private
          option :skip_install, type: :boolean, required: false,
                                default: SKIP_INSTALL_DEFAULT,
                                desc: "Skip app installation (Bundler, third-party Hanami plugins)"

          # @since 2.1.0
          # @api private
          option :skip_assets, type: :boolean, required: false,
                               default: SKIP_ASSETS_DEFAULT,
                               desc: "Skip assets"

          example [
            "bookshelf                # Generate a new Hanami app in `bookshelf/' directory, using `Bookshelf' namespace", # rubocop:disable Layout/LineLength
            "bookshelf --skip-install # Generate a new Hanami app, but it skips Hanami installation",
            "bookshelf --skip-assets  # Generate a new Hanami app without assets"
          ]

          # @since 2.0.0
          # @api private
          def initialize(
            fs: Hanami::CLI::Files.new,
            inflector: Dry::Inflector.new,
            bundler: CLI::Bundler.new(fs: fs),
            generator: Generators::Gem::App.new(fs: fs, inflector: inflector),
            **other
          )
            @bundler = bundler
            @generator = generator
            super(fs: fs, inflector: inflector, **other)
          end

          # @since 2.0.0
          # @api private
          def call(app:, skip_install: SKIP_INSTALL_DEFAULT, skip_assets: SKIP_ASSETS_DEFAULT, **)
            app = inflector.underscore(app)

            raise PathAlreadyExistsError.new(app) if fs.exist?(app)

            fs.mkdir(app)
            fs.chdir(app) do
              context = Generators::Context.new(inflector, app, skip_assets: skip_assets)
              generator.call(app, context: context) do
                if skip_install
                  out.puts "Skipping installation, please enter `#{app}' directory and run `bundle exec hanami install'"
                else
                  out.puts "Running Bundler install..."
                  bundler.install!
                  out.puts "Running Hanami install..."
                  run_install_commmand!
                end
              end
            end
          end

          private

          attr_reader :bundler
          attr_reader :generator

          def run_install_commmand!
            bundler.exec("hanami install").tap do |result|
              raise HanamiInstallError.new(result.err) unless result.successful?
            end
          end
        end
      end
    end
  end
end
