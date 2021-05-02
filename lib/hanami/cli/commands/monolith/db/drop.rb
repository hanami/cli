# frozen_string_literal: true

require_relative "../../application"

module Hanami
  module CLI
    module Commands
      module Monolith
        module DB
          class Drop < Application
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
