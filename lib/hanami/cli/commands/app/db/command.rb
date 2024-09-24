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
                inflector: inflector,
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

            def all_databases # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
              slices = [app] + app.slices.with_nested

              slice_gateways_by_database_url = slices.each_with_object({}) { |slice, hsh|
                db_provider_source = slice.container.providers[:db]&.source
                next unless db_provider_source

                db_provider_source.database_urls.each do |gateway, url|
                  hsh[url] ||= []
                  hsh[url] << {slice: slice, gateway: gateway}
                end
              }

              slice_gateways_by_database_url.each_with_object([]) { |(url, slice_gateways), arr|
                slice_gateways_with_config = slice_gateways.select {
                  _1[:slice].root.join("config", "db").directory?
                }

                db_slice_gateway = slice_gateways_with_config.first || slice_gateways.first
                database = Utils::Database.database_class(url).new(
                  slice: db_slice_gateway.fetch(:slice),
                  gateway_name: db_slice_gateway.fetch(:gateway),
                  system_call: system_call
                )

                warn_on_misconfigured_database database, slice_gateways.map { _1.fetch(:slice) }

                arr << database
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

            def warn_on_misconfigured_database(database, slices) # rubocop:disable Metrics/AbcSize
              if slices.length > 1
                out.puts <<~STR
                  WARNING: Database #{database.name} is configured for multiple config/db/ directories:

                  #{slices.map { "- " + _1.root.relative_path_from(_1.app.root).join("config", "db").to_s }.join("\n")}

                  Migrating database using #{database.slice.slice_name.to_s.inspect} slice only.

                STR
              elsif !database.db_config_dir?
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
