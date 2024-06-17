# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          module Structure
            # @api private
            class Load < DB::Command
              STRUCTURE_PATH = File.join("config", "db", "structure.sql").freeze
              private_constant :STRUCTURE_PATH

              desc "Loads database from config/db/structure.sql file"

              # @api private
              def call(app: false, slice: nil, command_exit: method(:exit), **)
                # TODO: handle exit_codes here

                databases(app: app, slice: slice).each do |database|
                  structure_path = database.slice.root.join(STRUCTURE_PATH)
                  next unless structure_path.exist?

                  relative_structure_path = structure_path.relative_path_from(database.slice.app.root)
                  measure("#{database.name} structure loaded from #{relative_structure_path}") do
                    database.exec_load_command.tap do |result|
                      unless result.successful?
                        out.puts result.err
                        break false
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
