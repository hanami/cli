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

              command_exit = -> code { throw :command_exited, code }
              command_args = {slice: slice, command_exit: command_exit}

              # Since we're operating on potentially multiple gateways for a given slice, we need to
              # run our operatiopns in a particular order to satisfy our ROM/Sequel's migrator
              # setup, which requires _all_ the databases in a slice to be created before we can use
              # the migrator.
              #
              # So, create/load every database first, before any other operations.
              databases(app: app, slice: slice).each do |database|
                db_command_args = {
                  **command_args,
                  app: !slice,
                  gateway: database.gateway_name.to_s
                }

                exit_code = catch :command_exited do
                  unless database.exists?
                    run_command(DB::Create, **db_command_args)
                    run_command(DB::Structure::Load, **db_command_args)
                  end

                  nil
                end

                exit_codes << exit_code if exit_code
              end

              # Once all databases are created, the migrator will load, and we can migrate each one.
              databases(app: app, slice: slice).each do |database|
                db_command_args = {
                  **command_args,
                  app: !slice,
                  gateway: database.gateway_name.to_s
                }

                run_command(DB::Migrate, **db_command_args)
              end

              # Finally, load the seeds for the slice overall, which is a once-per-slice operation.
              run_command(DB::Seed, **command_args)

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
