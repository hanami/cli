require_relative "../../app/command"
require_relative "create"
require_relative "drop"
require_relative "migrate"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          class Reset < App::Command
            desc "Drop, create, and migrate database"

            # @api private
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
