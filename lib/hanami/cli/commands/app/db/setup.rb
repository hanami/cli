# frozen_string_literal: true

require_relative "../../app/command"
require_relative "create"
require_relative "migrate"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          class Setup < App::Command
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
