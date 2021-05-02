# frozen_string_literal: true

require "shellwords"
require_relative "database"

module Hanami
  module CLI
    module Commands
      module DB
        module Utils
          class Postgres < Database
            def create_command
              system(cli_env_vars, "createdb #{escaped_name}")
            end

            def drop_command
              system(cli_env_vars, "dropdb #{escaped_name}")
            end

            def dump_command
              system(cli_env_vars, "pg_dump --schema-only --no-owner #{escaped_name} > #{dump_file}")
            end

            def load_command
              raise "Not Implemented Yet"
            end

            def escaped_name
              Shellwords.escape(name)
            end

            def cli_env_vars
              @cli_env_vars ||= {}.tap do |vars|
                vars["PGHOST"] = config.host.to_s
                vars["PGPORT"] = config.port.to_s if config.port
                vars["PGUSER"] = config.user.to_s if config.user
                vars["PGPASSWORD"] = config.pass.to_s if config.pass
              end
            end

            def dump_file
              "#{root_path}/db/structure.sql"
            end
          end
        end
      end
    end
  end
end
