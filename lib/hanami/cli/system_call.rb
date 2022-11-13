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

        attr_reader :exit_code, :out, :err

        def initialize(exit_code:, out:, err:)
          @exit_code = exit_code
          @out = out
          @err = err
        end

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
      def call(cmd, env: {})
        exitstatus = nil
        out = nil
        err = nil

        ::Bundler.with_unbundled_env do
          Open3.popen3(env, cmd) do |stdin, stdout, stderr, wait_thr|
            yield stdin, stdout, stderr, wait_thr if block_given?

            stdin.close

            exitstatus = wait_thr&.value&.exitstatus
            out = Thread.new { stdout.read }.value.strip
            err = Thread.new { stderr.read }.value.strip
          end
        end

        Result.new(exit_code: exitstatus, out: out, err: err)
      end
    end
  end
end
