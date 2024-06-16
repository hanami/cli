# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          class Create < DB::Command
            desc "Create databases"

            def call(app: false, slice: nil, command_exit: method(:exit), **)
              exit_codes = []

              databases(app: app, slice: slice).each do |database|
                result = database.exec_create_command
                exit_codes << result.exit_code if result.respond_to?(:exit_code)

                if result == true || result.successful?
                  out.puts "=> database #{database.name} created"
                else
                  out.puts "=> failed to create database #{database.name}"
                  out.puts "#{result.err}\n"
                end
              end

              exit_codes.each do |code|
                break command_exit.(code) if code > 0
              end
            end
          end
        end
      end
    end
  end
end
