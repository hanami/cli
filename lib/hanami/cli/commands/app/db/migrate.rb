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
                if database.migrations_dir?
                  migrate_database(database, target: target)
                else
                  warn_on_missing_migrations_dir(database)
                end
              end

              run_command(Structure::Dump, app: app, slice: slice, command_exit: command_exit) if dump
            end

            private

            def migrate_database(database, target:)
              return true unless migrations?(database)

              measure "database #{database.name} migrated" do
                if target
                  database.run_migrations(target: Integer(target))
                else
                  database.run_migrations
                end

                true
              end
            end

            def migrations?(database)
              database.migrations_dir? && database.sequel_migrator.files.any?
            end

            def warn_on_missing_migrations_dir(database)
              relative_path = database.slice.root.relative_path_from(database.slice.app.root).join("config", "db", "migrate").to_s
              out.puts <<~STR
                WARNING: Database #{database.name} expects migrations to be located within #{relative_path}/ but that folder does not exist.

                No database migrations can be run for this database.
              STR
            end
          end
        end
      end
    end
  end
end
