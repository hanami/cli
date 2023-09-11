# frozen_string_literal: true

require "open3"

module Hanami
  module CLI
    # @api private
    # @since 2.1.0
    class InteractiveSystemCall
      # @api private
      # @since 2.1.0
      def initialize(out: $stdout, err: $stderr)
        @out = out
        @err = err
        super()
      end

      # @api private
      # @since 2.1.0
      def call(executable, *args)
        ::Bundler.with_unbundled_env do
          threads = []
          exit_status = 0

          Open3.popen3(executable, *args) do |stdin, stdout, stderr, wait_thr|
            threads << Thread.new do
              stdout.each_line do |line|
                out.puts(line)
              end
            rescue IOError # FIXME: Check if this is legit
            end

            threads << Thread.new do
              stderr.each_line do |line|
                err.puts(line)
              end
            rescue IOError # FIXME: Check if this is legit
            end

            threads.each(&:join)

            exit_status = wait_thr.value
          end

          exit(exit_status)
        end
      end

      private

      # @api private
      # @since 2.1.0
      attr_reader :out, :err
    end
  end
end
