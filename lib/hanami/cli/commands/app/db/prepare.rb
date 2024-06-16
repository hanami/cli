# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          class Prepare < DB::Command
            desc "Prepare databases"

            def call(app: false, slice: nil, **)
              exit_codes = []

              databases(app: app, slice: slice).each do |database|
                command_exit = -> code { throw :command_exited, code }
                command_args = {slice: database.slice, command_exit: command_exit}

                exit_code = catch :command_exited do
                  unless database.exists?
                    run_command(DB::Create, **command_args)
                    run_command(DB::Structure::Load, **command_args)
                  end

                  run_command(DB::Migrate, **command_args)
                  run_command(DB::Seed, **command_args)
                  nil
                end

                exit_codes << exit_code if exit_code
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
