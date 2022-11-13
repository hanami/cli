# frozen_string_literal: true

require_relative "../../app/command"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          class Drop < App::Command
            desc "Delete database"

            # @api private
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
