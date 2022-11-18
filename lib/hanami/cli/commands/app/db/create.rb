# frozen_string_literal: true

require_relative "../../app/command"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          class Create < App::Command
            desc "Create database"

            # @api private
            def call(**)
              if database.create_command
                out.puts "=> database #{database.name} created"
              else
                out.puts "=> failed to create database #{database.name}"
                exit $?.exitstatus
              end
            end
          end
        end
      end
    end
  end
end
