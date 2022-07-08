# frozen_string_literal: true

require_relative "../../../app/command"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          module Structure
            class Dump < App::Command
              desc "Dumps database structure to db/structure.sql file"

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
