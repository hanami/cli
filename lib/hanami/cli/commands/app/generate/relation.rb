# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        module Generate
          # @since 2.2.0
          # @api private
          class Relation < Command
            argument :name, required: true, desc: "Relation name"

            example [
              %(books               (MyApp::Relation::Book)),
              %(books/drafts        (MyApp::Relations::Books::Drafts)),
              %(books --slice=admin (Admin::Relations::Books)),
            ]

            # @since 2.2.0
            # @api private
            def generator_class
              Generators::App::Relation
            end
          end
        end
      end
    end
  end
end
