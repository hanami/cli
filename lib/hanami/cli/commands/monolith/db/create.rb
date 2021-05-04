# frozen_string_literal: true

require_relative "../../application"

module Hanami
  module CLI
    module Commands
      module Monolith
        module DB
          class Create < Application
            desc "Create database"

            def call(**)
              if database.create_command
                out.puts "=> database #{database.name} created"
              else
                out.puts "=> failed to create database #{database.name}"
              end
            end
          end
        end
      end
    end
  end
end
