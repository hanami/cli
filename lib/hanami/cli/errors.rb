# frozen_string_literal: true

module Hanami
  module CLI
    # @since 0.1.0
    # @api public
    class Error < StandardError
    end

    # @since 2.0.0
    # @api public
    class NotImplementedError < Error
    end

    # @since 2.0.0
    # @api public
    class BundleInstallError < Error
      def initialize(message)
        super("`bundle install' failed\n\n\n#{message.inspect}")
      end
    end

    # @since 2.0.0
    # @api public
    class HanamiInstallError < Error
      def initialize(message)
        super("`hanami install' failed\n\n\n#{message.inspect}")
      end
    end

    # @since 2.1.0
    # @api public
    class HanamiExecError < Error
      def initialize(cmd, message)
        super("`bundle exec hanami #{cmd}' failed\n\n\n#{message.inspect}")
      end
    end

    # @since 2.0.0
    # @api public
    class PathAlreadyExistsError < Error
      def initialize(path)
        super("Cannot create new Hanami app in an existing path: `#{path}'")
      end
    end

    # @since 2.0.0
    # @api public
    class MissingSliceError < Error
      def initialize(slice)
        super("slice `#{slice}' is missing, please generate with `hanami generate slice #{slice}'")
      end
    end

    # @since 2.0.0
    # @api public
    class InvalidURLError < Error
      def initialize(url)
        super("invalid URL: `#{url}'")
      end
    end

    # @since 2.0.0
    # @api public
    class InvalidURLPrefixError < Error
      def initialize(url)
        super("invalid URL prefix: `#{url}'")
      end
    end

    # @since 2.0.0
    # @api public
    class InvalidActionNameError < Error
      def initialize(name)
        super("cannot parse controller and action name: `#{name}'\n\texample: `hanami generate action users.show'")
      end
    end

    # @since 2.0.0
    # @api public
    class UnknownHTTPMethodError < Error
      def initialize(name)
        super("unknown HTTP method: `#{name}'")
      end
    end

    # @since 2.0.0
    # @api public
    class UnsupportedDatabaseSchemeError < Error
      def initialize(scheme)
        super("`#{scheme}' is not a supported db scheme")
      end
    end

    # @since x.x.x
    # @api public
    class NameNeedsNamespaceError < Error; end
  end
end
