# frozen_string_literal: true

module Hanami
  module CLI
    module Generators
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

        # @since 2.0.0
        # @api private
        def self.prerelease?
          version =~ /alpha|beta|rc/
        end

        # @since 2.0.0
        # @api private
        #
        # @example
        #   Hanami::VERSION # => 2.0.0
        #   Hanami::CLI::Generators::Version.stable_version # => "2.0"
        def self.stable_version
          version.scan(/\A\d{1,2}\.\d{1,2}/).first
        end

        # @since 2.0.0
        # @api private
        #
        # @example
        #   Hanami::VERSION # => 2.0.0.alpha8.1
        #   Hanami::CLI::Generators::Version.stable_version # => "2.0.0.alpha"
        def self.prerelease_version
          version.sub(/[[[:digit:]].]*\Z/, "")
        end
      end
    end
  end
end
