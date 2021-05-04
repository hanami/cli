# frozen_string_literal: true

require "irb"
require_relative "core"

module Hanami
  module CLI
    module Repl
      # @since 2.0.0
      # @api public
      class Irb < Core
        # @api public
        def start
          ARGV.shift until ARGV.empty?
          TOPLEVEL_BINDING.eval('self').extend(context)

          IRB.conf[:PROMPT] = {}

          IRB.conf[:PROMPT][:MY_PROMPT] = {
            :AUTO_INDENT => true,
            :PROMPT_I =>  ">> ",
            :PROMPT_S => nil,
            :PROMPT_C => nil,
            :RETURN => "    ==>%s\n"
          }

          IRB.conf[:PROMPT_MODE] = :MY_PROMPT

          IRB.start
        end

        private

        # @api private
        def conf
          @conf ||= IRB.conf
        end
      end
    end
  end
end
