# frozen_string_literal: true

require_relative "../../app/command"
require_relative "structure/dump"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          class Rollback < App::Command
            desc "Rollback database to a previous migration"

            option :target, desc: "Target migration number", aliases: ["-t"]
            option :dump, desc: "Dump structure after rolling back"

            # @api private
            def call(target: nil, dump: true, **)
              migration_code, migration_name = find_migration(target)

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

            private

            def find_migration(code)
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
