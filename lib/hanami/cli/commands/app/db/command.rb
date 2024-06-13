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

            attr_reader :system_call

            def initialize(
              out:, err:,
              system_call: SystemCall.new,
              **opts
            )
              super(out: out, err: err, **opts)
              @system_call = system_call
            end

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
              build_database(app)
            end

            def database_for_slice(slice)
              slice = inflector.underscore(Shellwords.shellescape(slice)).to_sym

              build_database(app.slices[slice])
            end

            def all_databases
              slices = [app] + app.slices.with_nested

              slices_by_database_url = slices.each_with_object({}) { |slice, hsh|
                provider = slice.container.providers[:db]
                next unless provider

                database_url = provider.source.database_url
                hsh[database_url] ||= []
                hsh[database_url] << slice
              }

              databases = slices_by_database_url.each_with_object([]) { |(url, slices), arr|
                slices_with_config = slices.select { _1.root.join("config", "db").directory? }

                database = build_database(slices_with_config.first || slices.first)

                warn_on_misconfigured_database database, slices_with_config

                arr << database
              }

              databases
            end

            def build_database(slice)
              Utils::Database[slice, system_call: system_call]
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
