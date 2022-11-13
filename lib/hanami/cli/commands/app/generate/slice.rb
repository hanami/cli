# frozen_string_literal: true

require "dry/inflector"
require "dry/files"
require "shellwords"

module Hanami
  module CLI
    module Commands
      module App
        module Generate
          class Slice < Command
            argument :name, required: true, desc: "The slice name"
            option :url, required: false, type: :string, desc: "The slice URL prefix"

            example [
              "admin          # Admin slice (/admin URL prefix)",
              "users --url=/u # Users slice (/u URL prefix)",
            ]

            def initialize(fs: Hanami::CLI::Files.new, inflector: Dry::Inflector.new,
                           generator: Generators::App::Slice.new(fs: fs, inflector: inflector), **)
              @generator = generator
              super(fs: fs)
            end

            def call(name:, url: nil, **)
              require "hanami/setup"

              app = inflector.underscore(Hanami.app.namespace)
              name = inflector.underscore(Shellwords.shellescape(name))
              url = sanitize_url_prefix(name, url)

              generator.call(app, name, url)
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
            rescue ArgumentError
              raise ArgumentError.new("invalid URL prefix: `#{url}'")
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
