# frozen_string_literal: true

require "hanami/cli/system_call"

module RSpec
  module Support
    module SystemCall
      private

      def successful_system_call_result
        klass = Hanami::CLI::SystemCall::Result
        klass.new(exit_code: klass.const_get(:SUCCESSFUL_EXIT_CODE), out: StringIO.new, err: StringIO.new)
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::SystemCall
end
