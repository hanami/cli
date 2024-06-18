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
          HEAD_DEFAULT = false
          private_constant :HEAD_DEFAULT

          # @since 2.1.0
          # @api private
          SKIP_ASSETS_DEFAULT = false
          private_constant :SKIP_ASSETS_DEFAULT

          # @since x.x.x
          # @api private
          SKIP_DB_DEFAULT = false
          private_constant :SKIP_DB_DEFAULT

          # @since x.x.x
          # @api private
          DATABASE_SQLITE = "sqlite"

          # @since x.x.x
          # @api private
          DATABASE_POSTGRES = "postgres"

          # @since x.x.x
          # @api private
          SUPPORTED_DATABASES = [DATABASE_SQLITE, DATABASE_POSTGRES]

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
          option :head, type: :boolean, required: false,
                        default: HEAD_DEFAULT,
                        desc: "Use Hanami HEAD version (from GitHub `main` branches)"

          # @since 2.1.0
          # @api private
          option :skip_assets, type: :boolean, required: false,
                               default: SKIP_ASSETS_DEFAULT,
                               desc: "Skip assets"

          # @since x.x.x
          # @api private
          option :skip_db, type: :boolean, required: false,
                           default: SKIP_DB_DEFAULT,
                           desc: "Skip database layer"

          # @since x.x.x
          # @api private
          option :database, type: :string, required: false,
                            default: DATABASE_SQLITE,
                            desc: "Database adapter (supported: sqlite, mysql, postgres)"

          # rubocop:disable Layout/LineLength
          example [
            "bookshelf                   # Generate a new Hanami app in `bookshelf/' directory, using `Bookshelf' namespace",
            "bookshelf --head            # Generate a new Hanami app, using Hanami HEAD version from GitHub `main' branches",
            "bookshelf --skip-install    # Generate a new Hanami app, but it skips Hanami installation",
            "bookshelf --skip-assets     # Generate a new Hanami app without assets",
            "bookshelf --skip-db         # Generate a new Hanami app without database layer",
            "bookshelf --database=sqlite # Generate a new Hanami app with a SQLite database (default)"
          ]
          # rubocop:enable Layout/LineLength

          # rubocop:disable Metrics/ParameterLists

          # @since 2.0.0
          # @api private
          def initialize(
            fs:, inflector:,
            bundler: CLI::Bundler.new(fs: fs),
            generator: Generators::Gem::App.new(fs: fs, inflector: inflector),
            system_call: SystemCall.new,
            **opts
          )
            super(fs: fs, inflector: inflector, **opts)
            @bundler = bundler
            @generator = generator
            @system_call = system_call
          end

          # rubocop:enable Metrics/ParameterLists

          # rubocop:disable Metrics/AbcSize

          # @since 2.0.0
          # @api private
          def call(
            app:,
            head: HEAD_DEFAULT,
            skip_install: SKIP_INSTALL_DEFAULT,
            skip_assets: SKIP_ASSETS_DEFAULT,
            skip_db: SKIP_DB_DEFAULT,
            database: DATABASE_SQLITE,
            **
          )
            app = inflector.underscore(app)

            raise PathAlreadyExistsError.new(app) if fs.exist?(app)
            raise DatabaseNotSupportedError.new(database, SUPPORTED_DATABASES) unless SUPPORTED_DATABASES.include?(database)

            fs.mkdir(app)
            fs.chdir(app) do
              context = Generators::Context.new(
                inflector,
                app,
                head: head,
                skip_assets: skip_assets,
                skip_db: skip_db,
                database: database,
                **
              )
              generator.call(app, context: context) do
                if skip_install
                  out.puts "Skipping installation, please enter `#{app}' directory and run `bundle exec hanami install'"
                else
                  out.puts "Running Bundler install..."
                  bundler.install!

                  unless skip_assets
                    out.puts "Running NPM install..."
                    system_call.call("npm", ["install"]).tap do |result|
                      unless result.successful?
                        puts "NPM ERROR:"
                        puts(result.err.lines.map { |line| line.prepend("    ") })
                      end
                    end
                  end

                  out.puts "Running Hanami install..."
                  run_install_command!(head: head)
                end
              end
            end
          end
          # rubocop:enable Metrics/AbcSize

          private

          attr_reader :bundler
          attr_reader :generator
          attr_reader :system_call

          def run_install_command!(head:)
            head_flag = head ? " --head" : ""
            bundler.exec("hanami install#{head_flag}").tap do |result|
              if result.successful?
                bundler.exec("check").successful? || bundler.exec("install")
              else
                raise HanamiInstallError.new(result.err)
              end
            end
          end
        end
      end
    end
  end
end
