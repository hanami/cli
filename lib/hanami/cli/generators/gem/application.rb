# frozen_string_literal: true

module Hanami
  module CLI
    module Generators
      module Gem
        module Application
          class << self
            def call(architecture, fs, inflector, command_line)
              require_relative "./application/#{architecture}"

              generator_name = inflector.classify(architecture).to_sym
              const_get(generator_name).new(fs: fs, inflector: inflector, command_line: command_line)
            end
            alias_method :[], :call
          end
        end
      end
    end
  end
end
