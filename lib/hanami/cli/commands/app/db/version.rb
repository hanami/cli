# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          class Version < DB::Command
            desc "Print schema version"

            # @api private
            def call(app: false, slice: nil, **)
              databases(app: app, slice: slice).each do |database|
                unless database.migrations_dir?
                  out.puts "=> Cannot find version for slice #{database.slice.slice_name.to_s.inspect}: missing config/db/migrate/ dir"
                  return
                end

                migration = database.applied_migrations.last
                version = migration ? File.basename(migration, ".*") : "not available"

                out.puts "=> #{database.name} current schema version is #{version}"
              end
            end
          end
        end
      end
    end
  end
end
