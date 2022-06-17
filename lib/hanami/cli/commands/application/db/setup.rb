# frozen_string_literal: true

require_relative "../../application/command"
require_relative "create"
require_relative "migrate"

module Hanami
  module CLI
    module Commands
      module Application
        module DB
          class Setup < Application::Command
            desc "Setup database"

            def call(**)
              run_command Create
              run_command Migrate
            end
          end
        end
      end
    end
  end
end
