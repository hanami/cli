# frozen_string_literal: true

require "shellwords"
require_relative "utils/database"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # Base class for `hanami` CLI commands intended to be executed within an existing Hanami
          # app.
          #
          # @since 2.2.0
          # @api private
          class Command < App::Command
            option :app, required: false, type: :boolean, default: false, desc: "Use app database"
            option :slice, required: false, desc: "Use database for slice"

            private

            def databases(app: false, slice: nil)
              if app
                [database_for_app]
              elsif slice
                [database_for_slice(slice)]
              else
                all_databases
              end
            end

            def database_for_app
              Utils::Database[app]
            end

            def database_for_slice(slice)
              slice = inflector.underscore(Shellwords.shellescape(slice)).to_sym

              Utils::Database[app.slices[slice]]
            end

            def all_databases
              slices = app.slices.with_nested << app

              slices_by_database_url = slices.each_with_object({}) { |slice, hsh|
                next unless slice.container.providers.find_and_load_provider(:db)

                slice.prepare :db
                database_url = slice["db.gateway"].connection.uri

                hsh[database_url] ||= []
                hsh[database_url] << slice
              }

              databases = slices_by_database_url.each_with_object([]) { |(url, slices), arr|
                slices_with_config = slices.select { _1.root.join("config", "db").directory? }

                database = Utils::Database[slices_with_config.first || slices.first]

                warn_on_misconfigured_database database, slices_with_config

                arr << database
              }

              databases
            end

            def warn_on_misconfigured_database(database, slices)
              if slices.length > 1
                out.puts <<~STR
                  WARNING: Database #{database.name} has config/db/ directories in multiple slices:

                  #{slices.map { "- " + _1.root.relative_path_from(_1.app.root).join("config", "db").to_s }.join("\n")}

                  Migrating database using #{database.slice.slice_name.to_s.inspect} slice only.

                STR
              elsif slices.length < 1
                out.puts <<~STR
                  WARNING: Database #{database.name} has no config/db/ directory.
                STR
              end
            end
          end
        end
      end
    end
  end
end
