# frozen_string_literal: true

require_relative "../../application/command"

module Hanami
  module CLI
    module Commands
      module Application
        module DB
          class Drop < Application::Command
            desc "Delete database"

            def call(**)
              if database.drop_command
                out.puts "=> database #{database.name} dropped"
              else
                out.puts "=> failed to drop #{database.name}"
              end
            end
          end
        end
      end
    end
  end
end
