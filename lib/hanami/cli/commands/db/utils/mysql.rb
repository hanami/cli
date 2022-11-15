# frozen_string_literal: true

require_relative "database"
require_relative "../../../errors"

module Hanami
  module CLI
    module Commands
      module DB
        module Utils
          class Mysql < Database
            def create_command
              raise Hanami::CLI::NotImplementedError
            end

            def dump_command
              raise Hanami::CLI::NotImplementedError
            end

            def load_command
              raise Hanami::CLI::NotImplementedError
            end
          end
        end
      end
    end
  end
end
