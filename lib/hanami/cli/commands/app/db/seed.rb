# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          class Seed < DB::Command
            SEEDS_PATH = "config/db/seeds.rb"
            private_constant :SEEDS_PATH

            desc "Load seed data"

            def call(app: false, slice: nil, **)
              databases(app: app, slice: slice).each do |database|
                seeds_path = database.slice.root.join(SEEDS_PATH)
                next unless seeds_path.file?

                relative_seeds_path = seeds_path.relative_path_from(database.slice.app.root)
                measure "seed data loaded from #{relative_seeds_path}" do
                  load seeds_path.to_s
                end
              end
            end
          end
        end
      end
    end
  end
end
