# frozen_string_literal: true

require_relative "../../app/command"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          class Create < App::Command
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
