# frozen_string_literal: true

require "hanami/cli/command"

module Hanami
  module CLI
    module Commands
      module Monolith
        class Version < Command
          def call(*)
            require "hanami/version"
            out.puts "v#{Hanami::VERSION}"
          end
        end
      end
    end
  end
end
