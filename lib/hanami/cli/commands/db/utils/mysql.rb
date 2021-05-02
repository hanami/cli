# frozen_string_literal: true

require_relative "database"

module Hanami
  module CLI
    module Commands
      module DB
        module Utils
          class Mysql < Database
            def create_command
              raise "Not Implemented Yet"
            end

            def dump_command
              raise "Not Implemented Yet"
            end

            def load_command
              raise "Not Implemented Yet"
            end
          end
        end
      end
    end
  end
end
