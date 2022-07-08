# frozen_string_literal: true

require_relative "database_config"

module Hanami
  module CLI
    module Commands
      module DB
        module Utils
          class Database
            attr_reader :app, :config

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

            def self.[](app)
              config = DatabaseConfig.new(app.settings.database_url)

              resolver = SCHEME_MAP.fetch(config.db_type) do
                raise "#{config.db_type} is not a supported db scheme"
              end

              klass = resolver.()

              klass.new(app: app, config: config)
            end

            def initialize(app:, config:)
              @app = app
              @config = config
            end

            def create_command
              raise NotImplementedError
            end

            def drop_command
              raise NotImplementedError
            end

            def dump_command
              raise NotImplementedError
            end

            def load_command
              raise NotImplementedError
            end

            def root_path
              app.root
            end

            def rom_config
              @rom_config ||=
                begin
                  app.prepare(:persistence)
                  app.container["persistence.config"]
                end
            end

            def name
              config.db_name
            end

            def gateway
              rom_config.gateways[:default]
            end

            def connection
              gateway.connection
            end

            def run_migrations(**options)
              require "rom/sql"
              ROM::SQL.with_gateway(gateway) do
                migrator.run(options)
              end
            end

            def migrator
              @migrator ||=
                begin
                  require "rom/sql"
                  ROM::SQL::Migration::Migrator.new(connection, path: File.join(root_path, "db/migrate"))
                end
            end

            def applied_migrations
              sequel_migrator.applied_migrations
            end

            private

            def sequel_migrator
              @sequel_migrator ||= begin
                require "sequel"
                Sequel.extension :migration
                Sequel::TimestampMigrator.new(migrator.connection, migrations_path, {})
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
