# frozen_string_literal: true

require "dry/inflector"
require "dry/files"
require "shellwords"
require_relative "../../../errors"

module Hanami
  module CLI
    module Commands
      module App
        module Generate
          # @since 2.0.0
          # @api private
          class Slice < Command
            argument :name, required: true, desc: "The slice name"
            option :url, required: false, type: :string, desc: "The slice URL prefix"

            # @since 2.2.0
            # @api private
            SKIP_DB_DEFAULT = false
            private_constant :SKIP_DB_DEFAULT

            # @since 2.2.0
            # @api private
            option :skip_db, type: :boolean, required: false,
                             default: SKIP_DB_DEFAULT,
                             desc: "Skip database"

            # @since 2.2.0
            # @api private
            APP_DB_DEFAULT = false
            private_constant :APP_DB_DEFAULT

            # @since 2.2.0
            # @api private
            option :app_db, type: :boolean, required: false,
                            default: APP_DB_DEFAULT,
                            desc: "Import slice's DB config from the app"

            # @since 2.2.0
            # @api private
            SLICE_DB_DEFAULT = true
            private_constant :SLICE_DB_DEFAULT

            # @since 2.2.0
            # @api private
            option :slice_db, type: :boolean, required: false,
                              default: SLICE_DB_DEFAULT,
                              desc: "Use separate DB config for the slice"

            example [
              "admin          # Admin slice (/admin URL prefix)",
              "users --url=/u # Users slice (/u URL prefix)",
            ]

            # @since 2.0.0
            # @api private
            def initialize(
              fs:, inflector:,
              generator: Generators::App::Slice.new(fs: fs, inflector: inflector),
              **opts
            )
              super(fs: fs, inflector: inflector, **opts)
              @generator = generator
            end

            # @since 2.0.0
            # @api private
            def call(
              name:,
              url: nil,
              skip_db: SKIP_DB_DEFAULT,
              app_db: APP_DB_DEFAULT,
              slice_db: false
              # We override the slice_db default value above,
              # due to making app_db, slice_db, and skip_db mutually exclusive.
              # We set the default value below after those checks.
            )
              require "hanami/setup"

              app = inflector.underscore(Hanami.app.namespace)
              name = inflector.underscore(Shellwords.shellescape(name))
              url = sanitize_url_prefix(name, url)

              if app_db && slice_db
                raise ConflictingOptionsError.new(:app_db, :slice_db)
              elsif skip_db && app_db
                raise ConflictingOptionsError.new(:skip_db, :app_db)
              elsif skip_db && slice_db
                raise ConflictingOptionsError.new(:skip_db, :slice_db)
              elsif !app_db && !skip_db
                slice_db = SLICE_DB_DEFAULT
              end

              generator.call(app, name, url, skip_db: skip_db, app_db: app_db, slice_db: slice_db)
            end

            private

            DEFAULT_URL_PREFIX = "/"
            private_constant :DEFAULT_URL_PREFIX

            attr_reader :generator

            def sanitize_url_prefix(name, url)
              result = url
              result = inflector.underscore(Shellwords.shellescape(result)) unless result.nil?

              result ||= DEFAULT_URL_PREFIX + name
              CLI::URL.call(result)
            rescue InvalidURLError
              raise InvalidURLPrefixError.new(url)
            end

            def valid_url?(url)
              return false if url.nil?

              url.start_with?(DEFAULT_URL_PREFIX)
            end
          end
        end
      end
    end
  end
end
