# frozen_string_literal: true

require "erb"
require "shellwords"
require "hanami/cli/generators/context"

module Hanami
  module CLI
    module Generators
      module Gem
        class Application
          def initialize(fs:, inflector:, command_line:)
            super()
            @fs = fs
            @inflector = inflector
            @command_line = command_line
          end

          def call(app, context: Context.new(inflector, app), &blk)
            generate_app(app, context)
            blk.call
          end

          private

          attr_reader :fs

          attr_reader :inflector

          attr_reader :command_line

          def generate_app(app, context) # rubocop:disable Metrics/AbcSize
            fs.write(".env", t("env.erb", context))

            fs.write("README.md", t("readme.erb", context))
            fs.write("Gemfile", t("gemfile.erb", context))
            fs.write("Rakefile", t("rakefile.erb", context))
            fs.write("config.ru", t("config_ru.erb", context))

            fs.write("config/application.rb", t("application.erb", context))
            fs.write("config/settings.rb", t("settings.erb", context))
            fs.write("config/routes.rb", t("routes.erb", context))

            fs.write("lib/tasks/.keep", t("keep.erb", context))
            fs.write("lib/#{app}/types.rb", t("types.erb", context))

            fs.write("app/actions/.keep", t("keep.erb", context))
            fs.write("app/action.rb", t("action.erb", context))
          end

          def template(path, context)
            require "erb"

            ERB.new(
              File.read(File.join(__dir__, "application", path))
            ).result(context.ctx)
          end

          alias_method :t, :template
        end
      end
    end
  end
end
