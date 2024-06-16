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
            class Postgres < Database
              def exec_create_command
                return true if exists?

                system_call.call("createdb #{escaped_name}", env: cli_env_vars)
              end

              def exec_drop_command
                return true unless exists?

                system_call.call("dropdb #{escaped_name}", env: cli_env_vars)
              end

              private def exists?
                result = system_call.call("psql -t -A -c '\\list #{escaped_name}'", env: cli_env_vars)
                result.successful? && result.out.include?("#{name}|") # start_with?
              end

              def exec_dump_command
                system_call.call(
                  "pg_dump --schema-only --no-privileges --no-owner --file #{structure_file} #{escaped_name}",
                  env: cli_env_vars
                )
              end

              def exec_load_command
                system_call.call(
                  "psql --set ON_ERROR_STOP=1 --quiet --no-psqlrc --output #{File::NULL} --file #{structure_file} #{escaped_name}",
                  env: cli_env_vars
                )
              end

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

              def structure_file
                slice.root.join("config/db/structure.sql")
              end

              def schema_migrations_sql_dump
                search_path = slice["db.gateway"].connection
                  .fetch("SHOW search_path").to_a.first
                  .fetch(:search_path)

                +"SET search_path TO #{search_path};\n\n" << super
              end
            end
          end
        end
      end
    end
  end
end
