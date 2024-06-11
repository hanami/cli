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
                databases(app: app, slice: slice).each do |database|
                  measure("#{database.name} structure dumped to config/db/structure.sql") do
                    database.dump_command
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
