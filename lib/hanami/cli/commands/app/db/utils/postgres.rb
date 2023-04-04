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
                system(cli_env_vars, "dropdb --force #{escaped_name}")
              end

              # @api private
              def dump_command
                system(cli_env_vars, "pg_dump --schema-only --no-owner #{escaped_name} > #{dump_file}")
              end

              # @api private
              def load_command
                raise "Not Implemented Yet"
              end

              # @api private
              def escaped_name
                Shellwords.escape(name)
              end

              # @api private
              def cli_env_vars
                @cli_env_vars ||= {}.tap do |vars|
                  vars["PGHOST"] = config.host.to_s
                  vars["PGPORT"] = config.port.to_s if config.port
                  vars["PGUSER"] = config.user.to_s if config.user
                  vars["PGPASSWORD"] = config.pass.to_s if config.pass
                end
              end

              # @api private
              def dump_file
                "#{root_path}/db/structure.sql"
              end
            end
          end
        end
      end
    end
  end
end
