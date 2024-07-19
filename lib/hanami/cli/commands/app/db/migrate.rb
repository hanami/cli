# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          class Migrate < DB::Command
            desc "Migrates database"

            option :target, desc: "Target migration number", aliases: ["-t"]
            option :dump, required: false, type: :boolean, default: true,
                          desc: "Dump the database structure after migrating"

            def call(target: nil, app: false, slice: nil, dump: true, command_exit: method(:exit), **)
              databases(app: app, slice: slice).each do |database|
                if migrations_dir_missing?(database)
                  warn_on_missing_migrations_dir(database)
                elsif no_migrations?(database)
                  warn_on_empty_migrations_dir(database)
                else
                  migrate_database(database, target: target)
                end
              end

              run_command(Structure::Dump, app: app, slice: slice, command_exit: command_exit) if dump
            end

            private

            def migrate_database(database, target:)
              measure "database #{database.name} migrated" do
                if target
                  database.run_migrations(target: Integer(target))
                else
                  database.run_migrations
                end
              end
            end

            def migrations_dir_missing?(database)
              !database.migrations_dir?
            end

            def no_migrations?(database)
              database.sequel_migrator.files.empty?
            end

            def warn_on_missing_migrations_dir(database)
              relative_path = database.slice.root.relative_path_from(database.slice.app.root).join("config", "db", "migrate").to_s
              out.puts <<~STR
                WARNING: Database #{database.name} expects migrations to be located within #{relative_path}/ but that folder does not exist.

                No database migrations can be run for this database.
              STR
            end

            def warn_on_empty_migrations_dir(database)
              relative_path = database.slice.root.relative_path_from(database.slice.app.root).join("config", "db", "migrate").to_s
              out.puts <<~STR
                WARNING: Database #{database.name} has the correct migrations folder #{relative_path}/ but that folder is empty.

                No database migrations can be run for this database.
              STR
            end
          end
        end
      end
    end
  end
end
