# frozen_string_literal: true

require_relative "database_config"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          module Utils
            # @api private
            class Database
              # @api private
              attr_reader :app

              # @api private
              attr_reader :config

              # @api private
              SCHEME_MAP = {
                "sqlite" => -> {
                  require_relative("sqlite")
                  Sqlite
                },
                "postgres" => -> {
                  require_relative("postgres")
                  Postgres
                },
                "postgresql" => -> {
                  require_relative("postgres")
                  Postgres
                },
                "mysql" => -> {
                  require_relative("mysql")
                  Mysql
                }
              }.freeze

              # @api private
              def self.[](app)
                database_url =
                  if app.key?(:settings) && app[:settings].respond_to?(:database_url)
                    app[:settings].database_url
                  else
                    ENV.fetch("DATABASE_URL")
                  end

                config = DatabaseConfig.new(database_url)

                resolver = SCHEME_MAP.fetch(config.db_type) do
                  raise "#{config.db_type} is not a supported db scheme"
                end

                klass = resolver.()

                klass.new(app: app, config: config)
              end

              # @api private
              def initialize(app:, config:)
                @app = app
                @config = config
              end

              # @api private
              def create_command
                raise Hanami::CLI::NotImplementedError
              end

              # @api private
              def drop_command(force: false)
                raise Hanami::CLI::NotImplementedError
              end

              # @api private
              def dump_command
                raise Hanami::CLI::NotImplementedError
              end

              # @api private
              def load_command
                raise Hanami::CLI::NotImplementedError
              end

              # @api private
              def root_path
                app.root
              end

              # @api private
              def rom_config
                @rom_config ||=
                  begin
                    app.prepare(:persistence)
                    app.container["persistence.config"]
                  end
              end

              # @api private
              def name
                config.db_name
              end

              # @api private
              def gateway
                rom_config.gateways[:default]
              end

              # @api private
              def connection
                gateway.connection
              end

              # @api private
              def run_migrations(**options)
                require "rom/sql"
                ROM::SQL.with_gateway(gateway) do
                  migrator.run(options)
                end
              end

              # @api private
              def migrator
                @migrator ||=
                  begin
                    require "rom/sql"
                    ROM::SQL::Migration::Migrator.new(connection, path: File.join(root_path, "db/migrate"))
                  end
              end

              # @api private
              def applied_migrations
                sequel_migrator.applied_migrations
              end

              private

              def sequel_migrator
                @sequel_migrator ||= begin
                  require "sequel"
                  Sequel.extension :migration

                  require "rom/sql"
                  ROM::SQL.with_gateway(gateway) do
                    Sequel::TimestampMigrator.new(migrator.connection, migrations_path, {})
                  end
                end
              end

              def migrations_path
                File.join(root_path, "db/migrate")
              end
            end
          end
        end
      end
    end
  end
end
