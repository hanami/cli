# frozen_string_literal: true

require "irb"
require_relative "core"
require "byebug"

module Hanami
  module CLI
    module Repl
      class Irb < Core
        def start
          # FIXME: this is broken, no idea how to start an IRB session
          #        with our context as its binding
          IRB.start
        end
      end
    end
  end
end
