# frozen_string_literal: true

require_relative "database"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          module Utils
            # @api private
            class Mysql < Database
              # @api private
              def exec_create_command
                return true if exists?

                exec_cli("mysql", %(-e "CREATE DATABASE #{escaped_name}"))
              end

              # @api private
              # @since 2.2.0
              def exec_drop_command
                return true unless exists?

                exec_cli("mysql", %(-e "DROP DATABASE #{escaped_name}"))
              end

              # @api private
              # @since 2.2.0
              def exists?
                result = exec_cli("mysql", %(-e "SHOW DATABASES LIKE '#{name}'" --batch))

                result.successful? && result.out != ""
              end

              # @api private
              def exec_dump_command
                exec_cli(
                  "mysqldump",
                  "--no-data --routines --skip-comments --result-file=#{structure_file} #{escaped_name}"
                )
              end

              # @api private
              def exec_load_command
                raise Hanami::CLI::NotImplementedError
              end

              private

              def escaped_name
                Shellwords.escape(name)
              end

              def exec_cli(cli_name, cli_args)
                system_call.call(
                  "#{cli_name} #{cli_options} #{cli_args}",
                  env: cli_env_vars
                )
              end

              def cli_options
                [].tap { |opts|
                  opts << "--host=#{Shellwords.escape(database_uri.host)}" if database_uri.host
                  opts << "--port=#{Shellwords.escape(database_uri.port)}" if database_uri.port
                  opts << "--user=#{Shellwords.escape(database_uri.user)}" if database_uri.user
                }.join(" ")
              end

              def cli_env_vars
                @cli_env_vars ||= {}.tap do |vars|
                  vars["MYSQL_PWD"] = database_uri.password.to_s if database_uri.password
                end
              end
            end
          end
        end
      end
    end
  end
end
