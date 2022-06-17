# frozen_string_literal: true

require_relative "../../application/command"
require_relative "create"
require_relative "drop"
require_relative "migrate"

module Hanami
  module CLI
    module Commands
      module Application
        module DB
          class Reset < Application::Command
            desc "Drop, create, and migrate database"

            def call(**)
              run_command Drop
              run_command Create
              run_command Migrate
            end
          end
        end
      end
    end
  end
end
