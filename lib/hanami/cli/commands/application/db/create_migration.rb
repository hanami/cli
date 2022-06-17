# frozen_string_literal: true

require_relative "../../application/command"
require_relative "structure/dump"

module Hanami
  module CLI
    module Commands
      module Application
        module DB
          class CreateMigration < Application::Command
            desc "Create new migration file"

            argument :name, desc: "Migration file name"

            def call(name:, **)
              migrator = database.migrator
              version = migrator.generate_version

              measure "migration #{version}_#{name} created" do
                migrator.create_file(name, version)
              end
            end
          end
        end
      end
    end
  end
end
