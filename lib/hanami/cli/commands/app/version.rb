# frozen_string_literal: true

require "hanami/cli/command"

module Hanami
  module CLI
    module Commands
      module App
        class Version < Command
          desc "Print Hanami app version"

          def call(*)
            require "hanami/version"
            out.puts "v#{Hanami::VERSION}"
          end
        end
      end
    end
  end
end
