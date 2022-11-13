# frozen_string_literal: true

require_relative "database"
require_relative "../../../errors"

module Hanami
  module CLI
    module Commands
      module DB
        module Utils
          # @api private
          class Sqlite < Database
            # @api private
            def create_command
              rom_config
              true
            end

            # @api private
            def drop_command
              file_path.unlink
              true
            end

            # @api private
            def dump_command
              raise Hanami::CLI::NotImplementedError
            end

            # @api private
            def load_command
              raise Hanami::CLI::NotImplementedError
            end

            # @api private
            def file_path
              @file_path ||= Pathname("#{root_path}#{config.uri.path}").realpath
            end
          end
        end
      end
    end
  end
end
