# frozen_string_literal: true

require_relative "database"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          module Utils
            # @api private
            class Sqlite < Database
              def name
                @name ||= begin
                  db_path = Pathname(database_uri.path).expand_path
                  app_path = slice.app.root.realpath

                  if db_path.to_s.start_with?("#{app_path.to_s}#{File::SEPARATOR}")
                    db_path.relative_path_from(app_path).to_s
                  else
                    db_path.to_s
                  end
                end
              end

              def create_command
                true
              end

              def drop_command
                file_path.unlink
                true
              end

              def exec_dump_command
                raise Hanami::CLI::NotImplementedError
              end

              def exec_load_command
                raise Hanami::CLI::NotImplementedError
              end

              private

              def file_path
                @file_path ||= Pathname(slice.root.join(config.uri.path)).realpath
              end
            end
          end
        end
      end
    end
  end
end
