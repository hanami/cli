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
          def call(name, slice)
            ensure_valid_name name

            name = inflector.underscore(name)
            slice = inflector.underscore(slice) if slice

            if slice
              generate_for_slice(name, slice)
            else
              generate_for_app(name)
            end
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

          def generate_for_slice(name, slice)
            slice_dir = fs.join("slices", slice)
            raise MissingSliceError.new(slice) unless fs.directory?(slice_dir)

            migrate_dir = fs.join(slice_dir, "config", "db", "migrate")
            fs.mkdir_p migrate_dir

            fs.write fs.join(migrate_dir, file_name(name)), FILE_CONTENTS
          end

          def generate_for_app(name)
            migrate_dir = fs.join("config", "db", "migrate")
            fs.mkdir_p migrate_dir

            fs.write fs.join(migrate_dir, file_name(name)), FILE_CONTENTS
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
