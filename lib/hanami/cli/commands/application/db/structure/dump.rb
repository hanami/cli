# frozen_string_literal: true

require_relative "../../../application/command"

module Hanami
  module CLI
    module Commands
      module Application
        module DB
          module Structure
            class Dump < Application::Command
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
