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
              # @api private
              def create_command
                existing_stdout, status = Open3.capture2(cli_env_vars, "psql -t -c '\\l #{escaped_name}'")

                return true if status.success? && existing_stdout.include?(escaped_name)

                system(cli_env_vars, "createdb #{escaped_name}")
              end

              # @api private
              def drop_command
                system(cli_env_vars, "dropdb #{escaped_name}")
              end

              # @api private
              def dump_command
                system_call.call(
                  "pg_dump --schema-only --no-privileges --no-owner --file #{structure_file} #{escaped_name}",
                  env: cli_env_vars
                )
              end

              # @api private
              def exec_load_command
                system_call.call(
                  "psql --set ON_ERROR_STOP=1 --quiet --no-psqlrc --output #{File::NULL} --file #{structure_file} #{escaped_name}",
                  env: cli_env_vars
                )
              end

              # @api private
              def escaped_name
                Shellwords.escape(name)
              end

              # @api private
              def cli_env_vars
                @cli_env_vars ||= {}.tap do |vars|
                  vars["PGHOST"] = database_uri.hostname.to_s
                  vars["PGPORT"] = database_uri.port.to_s if database_uri.port
                  vars["PGUSER"] = database_uri.user.to_s if database_uri.user
                  vars["PGPASSWORD"] = database_uri.password.to_s if database_uri.password
                end
              end

              # @api private
              def structure_file
                slice.root.join("config/db/structure.sql")
              end
            end
          end
        end
      end
    end
  end
end
