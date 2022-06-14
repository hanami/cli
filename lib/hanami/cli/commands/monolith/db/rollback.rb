# frozen_string_literal: true

require_relative "../../application"
require_relative "structure/dump"

module Hanami
  module CLI
    module Commands
      module Monolith
        module DB
          class Rollback < Application
            desc "Rollback database to a previous migration"

            option :target, desc: "Target migration number", aliases: ["-t"]
            option :dump, desc: "Dump structure after rolling back"

            def call(target: nil, dump: true, **)
              migration_code, migration_name = find_migration(target)

              if migration_name.nil?
                out.puts "==> migration file for target #{target} was not found"
                return
              end

              measure "database #{database.name} rolled back to #{migration_name}" do
                database.run_migrations(target: Integer(migration_code))
              end

              run_command Structure::Dump if dump
            end

            private

            def find_migration(code)
              migration = database.applied_migrations.then { |migrations|
                if code
                  migrations.detect { |m| m.split("_").first == code }
                else
                  migrations.last
                end
              }

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
