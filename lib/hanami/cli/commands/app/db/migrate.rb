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

            def call(target: nil, app: false, slice: nil, **)
              databases(app: app, slice: slice).each do |database|
                migrate_database(database, target: target)
              end
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
          end
        end
      end
    end
  end
end
