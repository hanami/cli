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
              command_exit = -> code { throw :command_exited, code }
              command_exit_arg = {command_exit: command_exit}

              # Since we're operating on potentially multiple gateways for a given slice, we need to
              # run our operatiopns in a particular order to satisfy our ROM/Sequel's migrator
              # setup, which requires _all_ the databases in a slice to be created before we can use
              # the migrator.
              #
              # So, create/load every database first, before any other operations.
              databases(app: app, slice: slice).each do |database|
                command_args = {
                  **command_exit_arg,
                  app: database.slice.app?,
                  slice: database.slice,
                  gateway: database.gateway_name.to_s
                }

                exit_code = catch :command_exited do
                  unless database.exists?
                    run_command(DB::Create, **command_args)
                    run_command(DB::Structure::Load, **command_args)
                  end

                  nil
                end

                return exit exit_code if exit_code.to_i > 1
              end

              # Once all databases are created, the migrator will properly load for each slice, and
              # we can migrate each database.
              databases(app: app, slice: slice).each do |database|
                command_args = {
                  **command_exit_arg,
                  app: database.slice.app?,
                  slice: database.slice,
                  gateway: database.gateway_name.to_s
                }

                exit_code = catch :command_exited do
                  run_command(DB::Migrate, **command_args)

                  nil
                end

                return exit exit_code if exit_code.to_i > 1
              end

              # Finally, load the seeds for the slice overall, which is a once-per-slice operation.
              run_command(DB::Seed, app: app, slice: slice)
            end
          end
        end
      end
    end
  end
end
