# frozen_string_literal: true

require_relative "../../application/command"

module Hanami
  module CLI
    module Commands
      module Application
        module DB
          class Create < Application::Command
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
