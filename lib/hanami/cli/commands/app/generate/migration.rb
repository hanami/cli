# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        module Generate
          # @since 2.2.0
          # @api private
          class Migration < Command
            argument :name, required: true, desc: "Migration name"
            option :slice, required: false, desc: "Slice name"

            example [
              %(create_posts),
              %(add_published_at_to_posts),
              %(create_users --slice=admin),
            ]

            def generator_class
              Generators::App::Migration
            end
          end
        end
      end
    end
  end
end
