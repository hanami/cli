# frozen_string_literal: true

require "hanami/cli/command"
require "hanami/cli/generators/app/slice"
require "dry/inflector"
require "dry/files"
require "shellwords"
require "hanami/cli/files"
require "hanami/cli/url"

module Hanami
  module CLI
    module Commands
      module App
        module Generate
          class Slice < Command
            argument :name, required: true, desc: "The slice name"
            option :url_prefix, required: false, type: :string, desc: "The slice URL prefix"

            def initialize(fs: Hanami::CLI::Files.new, inflector: Dry::Inflector.new,
                           generator: Generators::App::Slice.new(fs: fs, inflector: inflector), **)
              @generator = generator
              super(fs: fs)
            end

            def call(name:, url_prefix: nil, **)
              require "hanami/setup"

              app = inflector.underscore(Hanami.app.namespace)
              name = inflector.underscore(Shellwords.shellescape(name))
              url_prefix = sanitize_url_prefix(name, url_prefix)

              generator.call(app, name, url_prefix)
            end

            private

            DEFAULT_URL_PREFIX = "/"
            private_constant :DEFAULT_URL_PREFIX

            attr_reader :generator

            def sanitize_url_prefix(name, url_prefix)
              result = url_prefix
              result = inflector.underscore(Shellwords.shellescape(result)) unless result.nil?

              result ||= DEFAULT_URL_PREFIX + name
              CLI::URL.call(result)
            rescue ArgumentError
              raise ArgumentError.new("invalid URL prefix: `#{url_prefix}'")
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
