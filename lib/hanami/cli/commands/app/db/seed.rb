# frozen_string_literal: true

require_relative "../../app/command"
require_relative "structure/dump"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          class Seed < App::Command
            FILE_PATH = "db/seeds.rb"

            desc "Load seed data"

            # @api private
            def call(**)
              if has_file?
                measure "seed data loaded from #{FILE_PATH}" do
                  load full_file_path
                end
              else
                out.puts "=> #{FILE_PATH} not found"
              end
            end

            private

            def full_file_path
              File.join(app.root, FILE_PATH)
            end

            def has_file?
              File.exist?(full_file_path)
            end
          end
        end
      end
    end
  end
end
