# frozen_string_literal: true

module Hanami
  module CLI
    module Generators
      module App
        # @since 2.2.0
        # @api private
        class Migration
          # @since 2.2.0
          # @api private
          def initialize(fs:, inflector:, out: $stdout)
            @fs = fs
            @inflector = inflector
            @out = out
          end

          # @since 2.2.0
          # @api private
          def call(namespace:, name:, base_path:, **_opts)
            _namespace = namespace
            normalized_name = inflector.underscore(name)
            ensure_valid_name(normalized_name)

            base = if base_path == "app"
                     fs.join("slices", slice, "config", "db", "migrate")
                   else
                     fs.join("config", "db", "migrate")
                   end

            path = fs.join(base, file_name(normalized_name))

            fs.write(path, FILE_CONTENTS)
          end

          private

          attr_reader :fs, :inflector, :out

          VALID_NAME_REGEX = /^[_a-z0-9]+$/
          private_constant :VALID_NAME_REGEX

          def ensure_valid_name(name)
            unless VALID_NAME_REGEX.match?(name.downcase)
              raise InvalidMigrationNameError.new(name)
            end
          end

          def file_name(name)
            "#{Time.now.strftime(VERSION_FORMAT)}_#{name}.rb"
          end

          VERSION_FORMAT = "%Y%m%d%H%M%S"
          private_constant :VERSION_FORMAT

          FILE_CONTENTS = <<~RUBY
            # frozen_string_literal: true

            ROM::SQL.migration do
              # Add your migration here.
              #
              # See https://sequel.jeremyevans.net/rdoc/files/doc/migration_rdoc.html for details.
            end
          RUBY
          private_constant :FILE_CONTENTS
        end
      end
    end
  end
end
