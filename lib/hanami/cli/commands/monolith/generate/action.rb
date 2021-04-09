# frozen_string_literal: true

require "hanami/cli/command"
require "hanami/cli/generators/monolith/action"
require "dry/inflector"
require "dry/cli/utils/files"
require "shellwords"

module Hanami
  module CLI
    module Commands
      module Monolith
        module Generate
          class Action < Command
            # TODO: ideally the default format should lookup
            #       slice configuration (Action's `default_response_format`)
            DEFAULT_FORMAT = "html"
            private_constant :DEFAULT_FORMAT

            DEFAULT_SKIP_VIEW = false
            private_constant :DEFAULT_SKIP_VIEW

            argument :slice, required: true, desc: "The slice name"
            argument :name, required: true, desc: "The action name"
            option :format, required: false, type: :string, default: DEFAULT_FORMAT, desc: "The template format"
            option :skip_view, required: false, type: :boolean, default: DEFAULT_SKIP_VIEW,
                               desc: "Skip view and template generation"

            def initialize(fs: Dry::CLI::Utils::Files.new, inflector: Dry::Inflector.new,
                           generator: Generators::Monolith::Action.new(fs: fs, inflector: inflector), **)
              @generator = generator
              super(fs: fs)
            end

            def call(slice:, name:, format: DEFAULT_FORMAT, skip_view: DEFAULT_SKIP_VIEW, **)
              slice = inflector.underscore(Shellwords.shellescape(slice))
              name = inflector.underscore(Shellwords.shellescape(name))
              *controller, action = name.split(ACTION_SEPARATOR)

              if controller.empty?
                raise ArgumentError.new("cannot parse controller and action name: `#{name}'\n\texample: users.show")
              end

              out.puts "generating action #{name} for #{slice} slice"
              generator.call(slice, controller, action, format, skip_view)
            end

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
