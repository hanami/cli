# frozen_string_literal: true

module RSpec
  module Support
    module HanamiCLIEnvironment
      # Adjusts $0 and ARGV to match the values expected when the `hanami` CLI is invoked in
      # ordinary usage.
      #
      # This is a workaround for our current (comrpomise) approach of re-executing DB CLI commands
      # in test mode.
      #
      # @see Hanami::CLI::Commands::App::DB::Command#re_run_development_command_in_test
      def as_hanami_cli_with_args(args)
        original_0 = $0.dup
        original_argv = ARGV.dup

        $0 = "hanami"
        ARGV.replace(args)

        yield

        $0 = original_0
        ARGV.replace(original_argv)
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::HanamiCLIEnvironment
end
