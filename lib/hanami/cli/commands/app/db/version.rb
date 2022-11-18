# frozen_string_literal: true

require_relative "../../app/command"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          class Version < App::Command
            desc "Print schema version"

            option :target, desc: "Target migration number", aliases: ["-t"]

            # @api private
            def call(target: nil, **) # rubocop:disable Lint/UnusedMethodArgument
              migration = database.applied_migrations.last
              version = migration ? File.basename(migration, ".*") : "not available"

              out.puts "=> current schema version is #{version}"
            end
          end
        end
      end
    end
  end
end
