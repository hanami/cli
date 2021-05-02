# frozen_string_literal: true

require_relative "../../application"
require_relative "structure/dump"

module Hanami
  module CLI
    module Commands
      module Monolith
        module DB
          class SampleData < Application
            FILE_PATH = "db/sample_data.rb"

            desc "Load sample data"

            def call(**)
              if has_file?
                measure "sample data loaded from #{FILE_PATH}" do
                  load full_file_path
                end
              else
                out.puts "=> #{FILE_PATH} not found"
              end
            end

            private

            def full_file_path
              File.join(application.root, FILE_PATH)
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
