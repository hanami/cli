# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module App
        module Generate
          # @since 2.2.0
          # @api private
          class Migration < App::Command
            argument :name, required: true, desc: "Migration name"
            option :slice, required: false, desc: "Slice name"

            example [
              %(create_posts),
              %(add_published_at_to_posts),
              %(create_users --slice=admin),
            ]

            attr_reader :generator
            private :generator

            # @since 2.2.0
            # @api private
            def initialize(
              fs:, inflector:,
              generator: Generators::App::Migration.new(fs: fs, inflector: inflector),
              **opts
            )
              super(fs: fs, inflector: inflector, **opts)
              @generator = generator
            end

            # @since 2.2.0
            # @api private
            def call(name:, slice: nil, **)
              generator.call(name, slice)
            end
          end
        end
      end
    end
  end
end
