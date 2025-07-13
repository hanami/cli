# frozen_string_literal: true

require "pry"
require_relative "../../app/command"
require_relative "structure/dump"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          class Rollback < DB::Command
            desc "Rollback database to a previous migration"

            argument :steps, desc: "Number of migrations to rollback", required: false
            option :target, desc: "Target migration number", aliases: ["-t"]
            option :dump, desc: "Dump structure after rolling back", default: true
            option :gateway, required: false, desc: "Use database for gateway"

            def call(steps: nil, app: false, slice: nil, gateway: nil, target: nil, dump: true, command_exit: method(:exit), **)
              if !app && slice.nil? && (steps.nil? || (steps && code_is_number?(steps))) && target.nil?
                steps_count = steps.nil? ? 1 : Integer(steps)
                rollback_across_all_databases(steps: steps_count, dump: dump, gateway: gateway, command_exit: command_exit)
              else
                target = steps if steps && !target
                databases(app: app, slice: slice, gateway: gateway).each do |database|
                  migration_code, migration_name = find_migration(target, database)

                  if migration_name.nil?
                    output = if steps
                               "==> migration file for #{steps} migrations back was not found"
                             elsif target
                               "==> migration file for target #{target} was not found"
                             else
                               "==> no migrations to rollback"
                             end

                    out.puts output
                    return
                  end

                  measure "database #{database.name} rolled back to #{migration_name}" do
                    database.run_migrations(target: Integer(migration_code))

                    true
                  end

                  next unless dump && !re_running_in_test?

                  run_command(
                    Structure::Dump,
                    app: app, slice: slice, gateway: gateway,
                    command_exit: command_exit
                  )
                end
              end
            end

            private

            def rollback_across_all_databases(steps:, dump:, gateway:, command_exit:)
              all_databases = databases(app: false, slice: nil, gateway: gateway)

              # Collect all applied migrations across all databases with their source database
              all_migrations = []
              applied_migrations = {}
              all_databases.each do |database|
                applied_migrations[database] = database.applied_migrations
                applied_migrations[database].each do |migration|
                  timestamp = Integer(migration.split("_").first)
                  all_migrations << {
                    timestamp: timestamp,
                    name: File.basename(migration, ".*"),
                    database: database,
                    migration: migration
                  }
                end
              end

              if all_migrations.empty?
                out.puts "==> no migrations to rollback"
                return
              end

              all_migrations.sort_by! { |m| -m[:timestamp] }
              migrations_to_rollback = all_migrations.take(steps)

              migrations_to_rollback.each do |migration_info|
                database = migration_info[:database]
                migration_name = migration_info[:name]

                # Find the previous migration in this database
                current_index = applied_migrations[database].index { |m| m.include?(migration_info[:migration]) }

                next if current_index.nil? # This shouldn't happen, but I am not like 100% sure?

                target_code = if current_index.positive?
                                prev_migration = applied_migrations[database][current_index - 1]
                                prev_migration.split("_").first
                              else
                                # Roll back to before the first migration
                                (migration_info[:timestamp] - 1).to_s
                              end

                measure "database #{database.name} rolled back to before #{migration_name}" do
                  database.run_migrations(target: Integer(target_code))
                  true
                end

                next unless dump && !re_running_in_test?

                # We have to dump during the loop not after, because we might need to dump multiple structures
                # This however leads to also possibly dumping multiple times on the same database
                run_command(
                  Structure::Dump,
                  app: false, slice: database.slice.slice_name.to_s, gateway: database.gateway_name.to_s,
                  command_exit: command_exit
                )
              end
            end

            def find_migration(code, database)
              applied_migrations = database.applied_migrations

              return if applied_migrations.empty?

              # Rollback to initial state if we have only one migration and
              # no target is specified. In this case the rollback target
              # will be the current migration timestamp minus 1
              return initial_state(applied_migrations) if applied_migrations.one? && code.nil?

              # If code is a number representing steps to rollback
              if code_is_number?(code)
                steps = Integer(code)
                index = -1 - steps

                # If steps exceed available migrations, rollback all migrations
                # by using the first (oldest) migration
                migration =
                  if index < -applied_migrations.size
                    return initial_state(applied_migrations)
                  else
                    applied_migrations[index]
                  end
              else
                migration =
                  if code
                    applied_migrations.detect { |m| m.split("_").first == code }
                  else
                    applied_migrations[-2]
                  end
              end
              migration_code = migration&.split("_")&.first
              migration_name = migration ? File.basename(migration, ".*") : nil

              [migration_code, migration_name]
            end

            def initial_state(applied_migrations)
              migration = applied_migrations.first

              migration_code = Integer(migration.split("_").first) - 1
              migration_name = "initial state"

              [migration_code, migration_name]
            end

            def code_is_number?(code)
              code&.to_s&.match?(/^\d+$/) && !code.to_s.match?(/^\d{10,}$/)
            end
          end
        end
      end
    end
  end
end
