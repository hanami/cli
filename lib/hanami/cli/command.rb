# frozen_string_literal: true

require "dry/cli"
require "dry/files"
require "dry/inflector"

module Hanami
  module CLI
    # Base class for `hanami` CLI commands.
    #
    # @api public
    # @since 2.0.0
    class Command < Dry::CLI::Command
      # Returns a new command.
      #
      # This method does not need to be called directly when creating comments for the CLI. Commands
      # are registered as classes, and the CLI framework will initialize the command when needed.
      # This means that all parameters for `#initialize` should also be given default arguments.
      #
      # @param out [IO] I/O stream for standard command output
      # @param err [IO] I/O stream for comment errror output
      # @param fs [Dry::Files] object for managing file system interactions
      # @param inflector [Dry::Inflector] inflector for any command-level inflections
      #
      # @since 2.0.0
      # @api public
      def initialize(out: $stdout, err: $stderr, fs: Dry::Files.new, inflector: Dry::Inflector.new)
        super()
        @out = out
        @err = err
        @fs = fs
        @inflector = inflector
      end

      private

      # Returns the I/O stream for standard command output.
      #
      # @return [IO]
      #
      # @since 2.0.0
      # @api public
      attr_reader :out

      # Returns the I/O stream for command error output.
      #
      # @return [IO]
      #
      # @since 2.0.0
      # @api public
      attr_reader :err

      # Returns the object for managing file system interactions.
      #
      # @return [Dry::Files]
      #
      # @since 2.0.0
      # @api public
      attr_reader :fs

      # Returns the inflector.
      #
      # @return [Dry::Inflector]
      #
      # @since 2.0.0
      # @api public
      attr_reader :inflector
    end
  end
end
