# frozen_string_literal: true

require_relative "./system_call"

module Hanami
  module CLI
    class Git
      def initialize(system_call: SystemCall.new)
        @system_call = system_call
      end

      def init
        system_call.call("git init")
      end

      def init!
        init.tap do |result|
          raise "Git init failed\n\n\n#{result.err.inspect}" unless result.successful?
        end
      end

      private

      attr_reader :system_call
    end
  end
end
