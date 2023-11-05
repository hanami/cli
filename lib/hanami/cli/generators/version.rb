# frozen_string_literal: true

module Hanami
  module CLI
    module Generators
      # @since 2.0.0
      # @api private
      module Version
        # @since 2.0.0
        # @api private
        def self.version
          return Hanami::VERSION if defined?(Hanami::VERSION)

          Hanami::CLI::VERSION
        end

        # @since 2.0.0
        # @api private
        def self.gem_requirement
          result = if prerelease?
                     prerelease_version
                   else
                     stable_version
                   end

          "~> #{result}"
        end

        def self.npm_package_requirement
          result = version
          # Change "2.1.0.beta2.1" to "2.1.0-beta.2" (the only format tolerable by `npm install`)
          if prerelease?
            result = result
              .sub(/\.(alpha|beta|rc)/, '-\1')
              .sub(/(alpha|beta|rc)(\d+)(\..+)?$/, '\1.\2')
          end

          "^#{result}"
        end

        # @since 2.0.0
        # @api private
        def self.prerelease?
          version =~ /alpha|beta|rc/
        end

        # @example
        #   Hanami::VERSION # => 2.0.0
        #   Hanami::CLI::Generators::Version.stable_version # => "2.0"
        #
        # @since 2.0.0
        # @api private
        def self.stable_version
          version.scan(/\A\d{1,2}\.\d{1,2}/).first
        end

        # @example
        #   Hanami::VERSION # => 2.0.0.alpha8.1
        #   Hanami::CLI::Generators::Version.stable_version # => "2.0.0.alpha"
        #
        # @since 2.0.0
        # @api private
        def self.prerelease_version
          version.sub(/[[[:digit:]].]*\Z/, "")
        end
      end
    end
  end
end
