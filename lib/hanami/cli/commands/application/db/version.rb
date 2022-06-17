# frozen_string_literal: true

require_relative "../../application/command"

module Hanami
  module CLI
    module Commands
      module Application
        module DB
          class Version < Application::Command
            desc "Print schema version"

            option :target, desc: "Target migration number", aliases: ["-t"]

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
