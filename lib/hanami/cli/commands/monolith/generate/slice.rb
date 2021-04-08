# frozen_string_literal: true

require "hanami/cli/command"
require "hanami/cli/generators/monolith/slice"
require "dry/inflector"
require "dry/cli/utils/files"
require "shellwords"

module Hanami
  module CLI
    module Commands
      module Monolith
        module Generate
          class Slice < Command
            argument :name, required: true, desc: "The slice name"

            def initialize(fs: Dry::CLI::Utils::Files.new, inflector: Dry::Inflector.new,
                           generator: Generators::Monolith::Slice.new(fs: fs, inflector: inflector), **)
              @generator = generator
              super(fs: fs)
            end

            def call(name:, **)
              require "hanami/setup"

              app = inflector.underscore(Hanami.application.namespace)
              name = inflector.underscore(Shellwords.shellescape(name))

              out.puts "generating #{name} for #{app}"
              generator.call(app, name)
            end

            private

            attr_reader :generator
          end
        end
      end
    end
  end
end
