# frozen_string_literal: true

require "hanami/cli/commands/app/command"
require "hanami/cli/generators/app/action"
require "dry/inflector"
require "dry/files"
require "shellwords"

module Hanami
  module CLI
    module Commands
      module App
        module Generate
          class Action < App::Command
            # TODO: ideally the default format should lookup
            #       slice configuration (Action's `default_response_format`)
            DEFAULT_FORMAT = "html"
            private_constant :DEFAULT_FORMAT

            DEFAULT_SKIP_VIEW = false
            private_constant :DEFAULT_SKIP_VIEW

            argument :name, required: true, desc: "Action name"
            option :url, required: false, type: :string, desc: "Action URL"
            option :http, required: false, type: :string, desc: "Action HTTP method"
            # option :format, required: false, type: :string, default: DEFAULT_FORMAT, desc: "Template format"
            # option :skip_view, required: false, type: :boolean, default: DEFAULT_SKIP_VIEW,
            #                    desc: "Skip view and template generation"
            option :slice, required: false, desc: "Slice name"

            def initialize(fs: Dry::Files.new, inflector: Dry::Inflector.new,
                           generator: Generators::App::Action.new(fs: fs, inflector: inflector), **)
              @generator = generator
              super(fs: fs)
            end

            # rubocop:disable Metrics/ParameterLists
            def call(name:, url: nil, http: nil, format: DEFAULT_FORMAT, skip_view: DEFAULT_SKIP_VIEW, slice: nil, **)
              slice = inflector.underscore(Shellwords.shellescape(slice)) if slice
              name = inflector.underscore(Shellwords.shellescape(name))
              *controller, action = name.split(ACTION_SEPARATOR)

              if controller.empty?
                raise ArgumentError.new("cannot parse controller and action name: `#{name}'\n\texample: users.show")
              end

              generator.call(app.namespace, controller, action, url, http, format, skip_view, slice)
            end
            # rubocop:enable Metrics/ParameterLists

            private

            ACTION_SEPARATOR = "."
            private_constant :ACTION_SEPARATOR

            attr_reader :generator
          end
        end
      end
    end
  end
end
