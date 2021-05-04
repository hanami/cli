# frozen_string_literal: true

require_relative "../../application"
require_relative "create"
require_relative "migrate"

module Hanami
  module CLI
    module Commands
      module Monolith
        module DB
          class Setup < Application
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
