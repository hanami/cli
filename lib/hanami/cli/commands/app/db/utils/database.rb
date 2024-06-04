# frozen_string_literal: true

require "uri"
require_relative "database_config"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          module Utils
            # @api private
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

              def self.[](slice)
                unless slice.container.providers.find_and_load_provider(:db)
                  raise "this is not a db slice"
                end

                slice.prepare :db
                database_scheme = slice["db.gateway"].connection.uri.then { URI(_1).scheme }

                database_class = DATABASE_CLASS_RESOLVER[database_scheme].call
                database_class.new(slice: slice)
              end

              attr_reader :slice

              def initialize(slice:)
                @slice = slice
              end

              def name
                database_uri.path
              end

              def database_url
                gateway.connection.uri
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

              def create_command
                raise Hanami::CLI::NotImplementedError
              end

              def drop_command
                raise Hanami::CLI::NotImplementedError
              end

              def dump_command
                raise Hanami::CLI::NotImplementedError
              end

              def load_command
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
                  require "rom/sql"
                  ROM::SQL::Migration::Migrator.new(connection, path: migrations_path)
                end
              end

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

              def applied_migrations
                sequel_migrator.applied_migrations
              end

              def migrations_path
                slice.root.join(MIGRATIONS_DIR)
              end

              def migrations_dir?
                migrations_path.directory?
              end
            end
          end
        end
      end
    end
  end
end
