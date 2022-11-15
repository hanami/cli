# frozen_string_literal: true

require_relative "database"
require_relative "../../../errors"

module Hanami
  module CLI
    module Commands
      module DB
        module Utils
          class Sqlite < Database
            def create_command
              rom_config
              true
            end

            def drop_command
              file_path.unlink
              true
            end

            def dump_command
              raise Hanami::CLI::NotImplementedError
            end

            def load_command
              raise Hanami::CLI::NotImplementedError
            end

            def file_path
              @file_path ||= Pathname("#{root_path}#{config.uri.path}").realpath
            end
          end
        end
      end
    end
  end
end
