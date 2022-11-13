# frozen_string_literal: true

require_relative "database"
require_relative "../../../errors"

module Hanami
  module CLI
    module Commands
      module DB
        module Utils
          # @api private
          class Mysql < Database
            # @api private
            def create_command
              raise Hanami::CLI::NotImplementedError
            end

            # @api private
            def dump_command
              raise Hanami::CLI::NotImplementedError
            end

            # @api private
            def load_command
              raise Hanami::CLI::NotImplementedError
            end
          end
        end
      end
    end
  end
end
