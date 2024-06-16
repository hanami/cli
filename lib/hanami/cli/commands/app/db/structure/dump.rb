# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          module Structure
            # @api private
            class Dump < DB::Command
              desc "Dumps database structure to config/db/structure.sql file"

              # @api private
              def call(app: false, slice: nil, **)
                exit_codes = []

                databases(app: app, slice: slice).each do |database|
                  structure_path = database.slice.root.join("config", "db", "structure.sql")
                  relative_structure_path = structure_path.relative_path_from(database.slice.app.root)

                  measure("#{database.name} structure dumped to #{relative_structure_path}") do
                    catch :dump_failed do
                      result = database.exec_dump_command
                      exit_codes << result.exit_code if result.respond_to?(:exit_code)

                      unless result.successful?
                        out.puts result.err
                        throw :dump_failed, false
                      end

                      File.open(structure_path, "a") do |f|
                        f.puts "#{database.schema_migrations_sql_dump}\n"
                      end

                      true
                    end
                  end
                end

                exit_codes.each do |code|
                  break exit code if code > 0
                end
              end
            end
          end
        end
      end
    end
  end
end
