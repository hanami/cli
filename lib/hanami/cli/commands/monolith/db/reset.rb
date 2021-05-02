# frozen_string_literal: true

require_relative "../../application"
require_relative "create"
require_relative "drop"
require_relative "migrate"

module Hanami
  module CLI
    module Commands
      module Monolith
        module DB
          class Reset < Application
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
