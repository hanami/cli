# frozen_string_literal: true

require "uri"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          module Utils
            # @api private
            # @since 2.2.0
            class Database
              MIGRATIONS_DIR = "config/db/migrate"
              private_constant :MIGRATIONS_DIR

              DATABASE_CLASS_RESOLVER = Hash.new { |_, key|
                raise "#{key} is not a supported db scheme"
              }.update(
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
              ).freeze

              def self.[](slice, system_call:)
                provider = slice.container.providers[:db]
                raise "this is not a db slice" unless provider

                database_scheme = provider.source.database_url.then { URI(_1).scheme }
                database_class = DATABASE_CLASS_RESOLVER[database_scheme].call
                database_class.new(slice: slice, system_call: system_call)
              end

              attr_reader :slice

              attr_reader :system_call

              def initialize(slice:, system_call:)
                @slice = slice
                @system_call = system_call
              end

              def name
                # Strip leading / - should this be skipped for sqlite?
                database_uri.path.sub(%r{^/}, "")
              end

              def database_url
                slice.container.providers[:db].source.database_url
              end

              def database_uri
                @database_uri ||= URI(database_url)
              end

              def gateway
                slice["db.config"].gateways[:default]
              end

              def connection
                gateway.connection
              end

              def exec_create_command
                raise Hanami::CLI::NotImplementedError
              end

              def exec_drop_command
                raise Hanami::CLI::NotImplementedError
              end

              def exists?
                raise Hanami::CLI::NotImplementedError
              end

              def exec_dump_command
                raise Hanami::CLI::NotImplementedError
              end

              def exec_load_command
                raise Hanami::CLI::NotImplementedError
              end

              def run_migrations(**options)
                require "rom/sql"
                ROM::SQL.with_gateway(gateway) do
                  migrator.run(options)
                end
              end

              def migrator
                @migrator ||= begin
                  slice.prepare :db

                  require "rom/sql"
                  ROM::SQL::Migration::Migrator.new(connection, path: migrations_path)
                end
              end

              def sequel_migrator
                @sequel_migrator ||= begin
                  slice.prepare :db

                  require "sequel"
                  Sequel.extension :migration

                  require "rom/sql"
                  ROM::SQL.with_gateway(gateway) do
                    Sequel::TimestampMigrator.new(migrator.connection, migrations_path, {})
                  end
                end
              end

              def applied_migrations
                sequel_migrator.applied_migrations
              end

              def migrations_path
                slice.root.join(MIGRATIONS_DIR)
              end

              def migrations_dir?
                migrations_path.directory?
              end

              def schema_migrations_sql_dump
                sql = +"INSERT INTO schema_migrations (filename) VALUES\n"
                sql << applied_migrations.map { |v| "('#{v}')" }.join(",\n")
                sql << ";"
                sql
              end
            end
          end
        end
      end
    end
  end
end
