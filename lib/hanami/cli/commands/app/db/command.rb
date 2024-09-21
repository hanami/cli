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
            option :app, required: false, type: :flag, default: false, desc: "Use app database"
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

            def run_command(klass, ...)
              klass.new(
                out: out,
                inflector: fs,
                fs: fs,
                system_call: system_call,
              ).call(...)
            end

            private

            def databases(app: false, slice: nil, gateway: nil)
              if gateway && !app && !slice
                err.puts "When specifying --gateway, an --app or --slice must also be given"
                exit 1
              end

              databases =
                if slice
                  [database_for_slice(slice, gateway: gateway)]
                elsif app
                  [database_for_slice(self.app, gateway: gateway)]
                else
                  all_databases
                end

              databases.flatten
            end

            def database_for_slice(slice, gateway: nil)
              unless slice.is_a?(Class) && slice < Hanami::Slice
                slice_name = inflector.underscore(Shellwords.shellescape(slice)).to_sym
                slice = app.slices[slice_name]
              end

              ensure_database_slice slice

              databases = build_databases(slice)

              if gateway
                databases.fetch(gateway.to_sym) do
                  err.puts %(No gateway "#{gateway}" in #{slice})
                  exit 1
                end
              else
                databases.values
              end
            end

            def all_databases
              slices = [app] + app.slices.with_nested

              slices_by_database_url = slices.each_with_object({}) { |slice, hsh|
                db_provider_source = slice.container.providers[:db]&.source
                next unless db_provider_source

                db_provider_source.database_urls.values.each do |url|
                  hsh[url] ||= []
                  hsh[url] << slice
                end
              }

              slices_by_database_url.each_with_object([]) { |(url, slices), arr|
                slices_with_config = slices.select { _1.root.join("config", "db").directory? }

                databases = build_databases(slices_with_config.first || slices.first).values

                databases.each do |database|
                  warn_on_misconfigured_database database, slices_with_config
                end

                arr.concat databases
              }
            end

            def build_databases(slice)
              Utils::Database.from_slice(slice: slice, system_call: system_call)
            end

            def ensure_database_slice(slice)
              return if slice.container.providers[:db]

              out.puts "#{slice} does not have a :db provider."
              exit 1
            end

            def warn_on_misconfigured_database(database, slices)
              if slices.length > 1
                out.puts <<~STR
                  WARNING: Database #{database.name} is configured for multiple config/db/ directories:

                  #{slices.map { "- " + _1.root.relative_path_from(_1.app.root).join("config", "db").to_s }.join("\n")}

                  Migrating database using #{database.slice.slice_name.to_s.inspect} slice only.

                STR
              elsif slices.length < 1
                relative_path = database.slice.root
                  .relative_path_from(database.slice.app.root)
                  .join("config", "db").to_s

                out.puts <<~STR
                  WARNING: Database #{database.name} expects the folder #{relative_path}/ to exist but it does not.

                STR
              end
            end
          end
        end
      end
    end
  end
end
