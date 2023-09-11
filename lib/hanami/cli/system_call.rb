# frozen_string_literal: true

# SystemCall#call is adapted from hanami-devtools as well as the Bundler source code. Bundler is
# released under the MIT license: https://github.com/bundler/bundler/blob/master/LICENSE.md.
#
# Thank you to the Bundler maintainers and contributors.

module Hanami
  module CLI
    # Facility for making convenient system calls and returning their results.
    #
    # @since 2.0.0
    # @api public
    class SystemCall
      # The result of a system call. Provides access to its standard out and error streams, plus
      # whether the command executed successfully.
      #
      # @since 2.0.0
      # @api public
      class Result
        SUCCESSFUL_EXIT_CODE = 0
        private_constant :SUCCESSFUL_EXIT_CODE

        # Returns the command's exit code
        #
        # @return [Integer]
        #
        # @since 2.0.0
        # @api public
        attr_reader :exit_code

        # Returns the command's standard output stream
        #
        # @return [IO]
        #
        # @since 2.0.0
        # @api public
        attr_reader :out

        # Returns the command's error ouptut stream
        #
        # @return [IO]
        #
        # @since 2.0.0
        # @api public
        attr_reader :err

        # @since 2.0.0
        # @api private
        def initialize(exit_code:, out:, err:)
          @exit_code = exit_code
          @out = out
          @err = err
        end

        # Returns true if the command executed successfully (if its {#exit_code} is 0).
        #
        # @return [Boolean]
        #
        # @since 2.0.0
        # @api public
        def successful?
          exit_code == SUCCESSFUL_EXIT_CODE
        end
      end

      # Executes the given system command and returns the result.
      #
      # @param cmd [String] the system command to execute
      # @param env [Hash<String, String>] an optional hash of environment variables to set before
      #   executing the command
      #
      # @overload call(cmd, env: {})
      #
      # @overload call(cmd, env: {}, &blk)
      #   Executes the command and passes the given block to the `Open3.popen3` method called
      #   internally.
      #
      #   @example
      #     call("info") do |stdin, stdout, stderr, wait_thread|
      #       # ...
      #     end
      #
      # @return [Result]
      #
      # @since 2.0.0
      # @api public
      def call(cmd, *args, env: {})
        exitstatus = nil
        out = nil
        err = nil

        ::Bundler.with_unbundled_env do
          Open3.popen3(env, command(cmd, *args)) do |stdin, stdout, stderr, wait_thr|
            yield stdin, stdout, stderr, wait_thr if block_given?

            stdin.close

            exitstatus = wait_thr&.value&.exitstatus
            out = Thread.new { stdout.read }.value.strip
            err = Thread.new { stderr.read }.value.strip
          end
        end

        Result.new(exit_code: exitstatus, out: out, err: err)
      end

      # @since 2.1.0
      # @api public
      def command(cmd, *args)
        [cmd, args].flatten(1).compact.join(" ")
      end
    end
  end
end
