# frozen_string_literal: true

require "hanami"
require "hanami/cli/middleware_stack_inspector"

module Hanami
  module CLI
    module Commands
      module App
        # List registered middlewares in the app router
        #
        # It outputs middlewares registered along with the paths where they
        # apply:
        #
        # ```
        # $ hanami middlewares
        # /    Rack::Session::Cookie args: [{:secret=>"foo"}]
        # ```
        #
        # Given arguments can be inspected:
        #
        # ```
        # $ hanami middlewares --with-arguments
        # /    Rack::Session::Cookie args: [{:secret=>"foo"}
        # ```
        class Middlewares < Hanami::CLI::Command
          desc "List all the registered middlewares"

          DEFAULT_WITH_ARGUMENTS = false

          option :with_arguments, default: DEFAULT_WITH_ARGUMENTS, required: false, desc: "Include inspected arguments", type: :boolean

          # @api private
          def call(with_arguments: DEFAULT_WITH_ARGUMENTS)
            require "hanami/prepare"
            out.puts MiddlewareStackInspector.new(stack: stack).inspect(include_arguments: with_arguments)
          end

          private

          def stack
            Hanami.app.router.middleware_stack
          end
        end
      end
    end
  end
end
