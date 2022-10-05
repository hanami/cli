# frozen_string_literal: true

require "dry/cli"
require "dry/files"
require "dry/inflector"

module Hanami
  module CLI
    class Command < Dry::CLI::Command
      def initialize(out: $stdout, err: $stderr, fs: Dry::Files.new, inflector: Dry::Inflector.new)
        super()
        @out = out
        @err = err
        @fs = fs
        @inflector = inflector
      end

      private

      attr_reader :out

      attr_reader :err

      attr_reader :fs

      attr_reader :inflector
    end
  end
end
