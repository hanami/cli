# frozen_string_literal: true

require "hanami/console/context"

require_relative "../application"

module Hanami
  module CLI
    module Commands
      module Monolith
        class Console < Application
          desc "Application REPL"

          def call(**_opts)
            require "pry"

            prompt = application_prompt

            Pry.config.prompt = Pry::Prompt.new(
              "hanami",
              "my custom prompt",
              [proc { |_obj, _| "#{prompt}> " }]
            )

            ctx = Hanami::Console::Context.new(application)

            Pry.start(ctx)
          end

          def application_prompt
            "#{application_name}[#{application_env}]"
          end

          def application_name
            (application.container.config.name || inflector.underscore(application.name)).split("/")[0]
          end

          def application_env
            application.container.env
          end

          def inflector
            application.inflector
          end
        end
      end
    end
  end
end
