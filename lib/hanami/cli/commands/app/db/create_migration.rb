require_relative "../../app/command"
require_relative "structure/dump"

module Hanami
  module CLI
    module Commands
      module App
        # @api private
        module DB
          # @api private
          class CreateMigration < App::Command
            desc "Create new migration file"

            argument :name, desc: "Migration file name"

            # @api private
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
