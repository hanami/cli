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
                "mysql2" => -> {
                  require_relative("mysql")
                  Mysql
                }
              ).freeze

              def self.from_slice(slice:, system_call:)
                provider = slice.container.providers[:db]
                raise "this is not a db slice" unless provider

                provider.source.database_urls.map { |(gateway_name, database_url)|
                  database_scheme = URI(database_url).scheme
                  database_class = DATABASE_CLASS_RESOLVER[database_scheme].call

                  database = database_class.new(
                    slice: slice,
                    gateway_name: gateway_name,
                    system_call: system_call
                  )

                  [gateway_name, database]
                }.to_h
              end

              attr_reader :slice
              attr_reader :gateway_name

              attr_reader :system_call

              def initialize(slice:, gateway_name:, system_call:)
                @slice = slice
                @gateway_name = gateway_name
                @system_call = system_call
              end

              def name
                database_uri.path.sub(%r{^/}, "")
              end

              def database_url
                slice.container.providers[:db].source.database_urls.fetch(gateway_name)
              end

              def database_uri
                @database_uri ||= URI(database_url)
              end

              def gateway
                slice["db.config"].gateways[gateway_name]
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
                path = slice.root.join("config", "db")

                if gateway_name == :default
                  path = path.join("migrate")
                else
                  path = path.join("#{gateway_name}_migrate")
                end

                path
              end

              def migrations_dir?
                migrations_path.directory?
              end

              def structure_file
                path = slice.root.join("config", "db")

                if gateway_name == :default
                  path.join("structure.sql")
                else
                  path.join("#{gateway_name}_structure.sql")
                end
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
