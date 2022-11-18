# frozen_string_literal: true

require_relative "../../../app/command"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          module Structure
            # @api private
            class Dump < App::Command
              desc "Dumps database structure to db/structure.sql file"

              # @api private
              def call(*)
                measure("#{database.name} structure dumped to db/structure.sql") do
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
