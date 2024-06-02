# frozen_string_literal: true

require_relative "../../app/command"
require_relative "structure/dump"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          class Migrate < DB::Command
            desc "Migrates database"

            option :target, desc: "Target migration number", aliases: ["-t"]

            def call(target: nil, **)
              # FIXME update this to work with new paths (plus app vs slice)

              measure "database #{database.name} migrated" do
                if target
                  database.run_migrations(target: Integer(target))
                else
                  database.run_migrations
                end

                true
              end
            end
          end
        end
      end
    end
  end
end
