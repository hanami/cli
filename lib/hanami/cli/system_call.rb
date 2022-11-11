# frozen_string_literal: true

module Hanami
  module CLI
    class SystemCall
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

      # Adapted from Bundler source code
      #
      # Bundler is released under MIT license
      # https://github.com/bundler/bundler/blob/master/LICENSE.md
      #
      # A special "thank you" goes to Bundler maintainers and contributors.
      #
      # Also adapted from `hanami-devtools` source code
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
