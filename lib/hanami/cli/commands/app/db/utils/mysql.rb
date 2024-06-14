# frozen_string_literal: true

require_relative "database"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          module Utils
            # @api private
            class Mysql < Database
              # @api private
              def create_command
                raise Hanami::CLI::NotImplementedError
              end

              # @api private
              def exec_dump_command
                raise Hanami::CLI::NotImplementedError
              end

              # @api private
              def exec_load_command
                raise Hanami::CLI::NotImplementedError
              end
            end
          end
        end
      end
    end
  end
end
