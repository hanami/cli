# frozen_string_literal: true

require "shellwords"
require "open3"
require_relative "database"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          module Utils
            # @api private
            # @since 2.2.0
            class Postgres < Database
              # @api private
              # @since 2.2.0
              def exec_create_command
                return true if exists?

                system_call.call("createdb #{escaped_name}", env: cli_env_vars)
              end

              # @api private
              # @since 2.2.0
              def exec_drop_command
                return true unless exists?

                system_call.call("dropdb #{escaped_name}", env: cli_env_vars)
              end

              # @api private
              # @since 2.2.0
              def exists?
                result = system_call.call("psql -t -A -c '\\list #{escaped_name}'", env: cli_env_vars)
                raise Hanami::CLI::DatabaseExistenceCheckError.new(result.err) unless result.successful?

                result.out.include?("#{name}|") # start_with?
              end

              # @api private
              # @since 2.2.0
              def exec_dump_command
                system_call.call(
                  "pg_dump --schema-only --no-privileges --no-owner --file #{structure_file} #{escaped_name}",
                  env: cli_env_vars
                )
              end

              # @api private
              # @since 2.2.0
              def exec_load_command
                system_call.call(
                  "psql --set ON_ERROR_STOP=1 --quiet --no-psqlrc --output #{File::NULL} --file #{structure_file} #{escaped_name}",
                  env: cli_env_vars
                )
              end

              def schema_migrations_sql_dump
                migrations_sql = super
                return unless migrations_sql
                
                search_path = gateway.connection
                  .fetch("SHOW search_path").to_a.first
                  .fetch(:search_path)

                +"SET search_path TO #{search_path};\n\n" << migrations_sql
              end

              private

              def escaped_name
                Shellwords.escape(name)
              end

              def cli_env_vars
                @cli_env_vars ||= {}.tap do |vars|
                  vars["PGHOST"] = database_uri.host.to_s if database_uri.host
                  vars["PGPORT"] = database_uri.port.to_s if database_uri.port
                  vars["PGUSER"] = database_uri.user.to_s if database_uri.user
                  vars["PGPASSWORD"] = database_uri.password.to_s if database_uri.password
                end
              end
            end
          end
        end
      end
    end
  end
end
