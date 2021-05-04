# frozen_string_literal: true

require_relative "../../application"

module Hanami
  module CLI
    module Commands
      module Monolith
        module DB
          class Version < Application
            desc "Print schema version"

            option :target, desc: "Target migration number", aliases: ["-t"]

            def call(target: nil, **)
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
