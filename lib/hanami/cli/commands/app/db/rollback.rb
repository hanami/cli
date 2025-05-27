# frozen_string_literal: true

require 'pry'
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
            option :dump, desc: "Dump structure after rolling back"

            def call(steps: nil, app: false, slice: nil, target: nil, dump: true, **)
              target = steps if steps && !target

              databases(app: app, slice: slice).each do |database|
                migration_code, migration_name = find_migration(target, database)

                if migration_name.nil?
                  output = if target
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

                run_command Structure::Dump if dump
              end
            end

            private

            def find_migration(code, database)
              # TODO: why entered twice in spec
              applied_migrations = database.applied_migrations

              return if applied_migrations.empty?

              # Rollback to initial state if we have only one migration and
              # no target is specified. In this case the rollback target
              # will be the current migration timestamp minus 1
              if applied_migrations.one? && code.nil?
                migration = applied_migrations.first

                migration_code = Integer(migration.split("_").first) - 1
                migration_name = "initial state"

                return [migration_code, migration_name]
              end

              # If code is a number representing steps to rollback
              if code&.to_s&.match?(/^\d+$/) && !code.to_s.match?(/^\d{10,}$/)
                steps = Integer(code)
                index = -1 - steps

                # Ensure we don't go beyond available migrations
                return if index < -applied_migrations.size

                migration = applied_migrations[index]
                migration_code = migration.split("_").first
                migration_name = File.basename(migration, ".*")

                return [migration_code, migration_name]
              end

              # Otherwise rollback to target or to previous migration
              migration =
                if code
                  applied_migrations.detect { |m| m.split("_").first == code }
                else
                  applied_migrations[-2]
                end

              return unless migration

              migration_code = code || migration.split("_").first
              migration_name = File.basename(migration, ".*")

              [migration_code, migration_name]
            end
          end
        end
      end
    end
  end
end
