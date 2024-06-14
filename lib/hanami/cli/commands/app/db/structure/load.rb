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
              desc "Loads database from config/db/structure.sql file"

              # @api private
              def call(app: false, slice: nil, **)
                databases(app: app, slice: slice).each do |database|
                  slice_root = database.slice.root.relative_path_from(database.slice.app.root)
                  structure_path = slice_root.join("config", "db", "structure.sql")

                  measure("#{database.name} structure loaded from #{structure_path}") do
                    database.load_command
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
