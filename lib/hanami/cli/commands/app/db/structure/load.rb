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
                  measure("#{database.name} structure loaded from config/db/structure.sql") do
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
