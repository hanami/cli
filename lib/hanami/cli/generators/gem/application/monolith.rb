# frozen_string_literal: true

require "erb"
require "shellwords"
require "hanami/cli/generators/context"

module Hanami
  module CLI
    module Generators
      module Gem
        module Application
          class Monolith
            def initialize(fs:, inflector:, command_line:)
              super()
              @fs = fs
              @inflector = inflector
              @command_line = command_line
            end

            def call(app, slice, slice_url_prefix, context: Context.new(inflector, app), &blk)
              generate_app(app, context)
              blk.call
              generate_slice!(slice, slice_url_prefix)
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

              fs.write("lib/#{app}/entities/.keep", t("keep.erb", context))
              fs.write("lib/#{app}/persistence/relations/.keep", t("keep.erb", context))
              fs.write("lib/#{app}/validation/contract.rb", t("validation_contract.erb", context))
              fs.write("lib/#{app}/view/context.rb", t("view_context.erb", context))
              fs.write("lib/#{app}/action.rb", t("action.erb", context))
              fs.write("lib/#{app}/entities.rb", t("entities.erb", context))
              fs.write("lib/#{app}/functions.rb", t("functions.erb", context))
              fs.write("lib/#{app}/operation.rb", t("operation.erb", context))
              fs.write("lib/#{app}/repository.rb", t("repository.erb", context))
              fs.write("lib/#{app}/types.rb", t("types.erb", context))
            end

            def generate_slice!(slice_name, slice_url_prefix)
              slice_name = Shellwords.shellescape(slice_name)
              slice_url_prefix = Shellwords.shellescape(slice_url_prefix)

              command_line.call("hanami generate slice #{slice_name} --url-prefix=#{slice_url_prefix}").tap do |result|
                raise "hanami generate slice #{slice_name} failed\n\n\n#{result.err.inspect}" unless result.successful?
              end
            end

            def template(path, context)
              require "erb"

              ERB.new(
                File.read(__dir__ + "/monolith/#{path}")
              ).result(context.ctx)
            end

            alias_method :t, :template
          end
        end
      end
    end
  end
end
