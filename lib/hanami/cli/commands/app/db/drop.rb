# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          class Drop < DB::Command
            desc "Delete databases"

            def call(app: false, slice: nil, **)
              exit_codes = []

              databases(app: app, slice: slice).each do |database|
                result = database.exec_drop_command
                exit_codes << result.exit_code if result.respond_to?(:exit_code)

                if result == true || result.successful?
                  out.puts "=> database #{database.name} dropped"
                else
                  out.puts "=> failed to drop database #{database.name}"
                  out.puts "#{result.err}\n"
                end
              end

              exit_codes.each do |code|
                break exit code if code > 0
              end
            end
          end
        end
      end
    end
  end
end
