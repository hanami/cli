# frozen_string_literal: true

require "hanami/cli/command"
require "hanami/cli/generators/slice"
require "dry/inflector"
require "dry/cli/utils/files"
require "shellwords"

module Hanami
  module CLI
    module Commands
      module Monolith
        module Generate
          class Slice < Command
            argument :slice, required: true, desc: "The slice name"

            def initialize(fs: Dry::CLI::Utils::Files.new, inflector: Dry::Inflector.new,
                           generator: Generators::Slice.new(fs: fs, inflector: inflector), **)
              @generator = generator
              super(fs: fs)
            end

            def call(slice:, **)
              require "hanami/setup"

              app = inflector.underscore(Hanami.application.namespace)
              slice = inflector.underscore(Shellwords.shellescape(slice))

              out.puts "generating #{slice} for #{app}"
              generator.call(app, slice)
            end

            private

            attr_reader :generator
          end
        end
      end
    end
  end
end
