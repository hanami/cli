# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          class Create < DB::Command
            desc "Create database"

            def call(app: false, slice: nil, **)
              databases(app: app, slice: slice).each do |database|
                result = database.exec_create_command

                if result == true || result.successful?
                  out.puts "=> database #{database.name} created"
                else
                  out.puts "=> failed to create database #{database.name}"
                  out.puts result.err
                  exit result.exit_code
                end
              end
            end
          end
        end
      end
    end
  end
end
