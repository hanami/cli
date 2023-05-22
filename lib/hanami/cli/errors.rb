module Hanami
  module CLI
    class Error < StandardError
    end

    class NotImplementedError < Error
    end

    class BundleInstallError < Error
      def initialize(message)
        super("`bundle install' failed\n\n\n#{message.inspect}")
      end
    end

    class HanamiInstallError < Error
      def initialize(message)
        super("`hanami install' failed\n\n\n#{message.inspect}")
      end
    end

    class PathAlreadyExistsError < Error
      def initialize(path)
        super("Cannot create new Hanami app in an existing path: `#{path}'")
      end
    end

    class MissingSliceError < Error
      def initialize(slice)
        super("slice `#{slice}' is missing, please generate with `hanami generate slice #{slice}'")
      end
    end

    class InvalidURLError < Error
      def initialize(url)
        super("invalid URL: `#{url}'")
      end
    end

    class InvalidURLPrefixError < Error
      def initialize(url)
        super("invalid URL prefix: `#{url}'")
      end
    end

    class InvalidActionNameError < Error
      def initialize(name)
        super("cannot parse controller and action name: `#{name}'\n\texample: `hanami generate action users.show'")
      end
    end

    class UnknownHTTPMethodError < Error
      def initialize(name)
        super("unknown HTTP method: `#{name}'")
      end
    end

    class UnsupportedDatabaseSchemeError < Error
      def initialize(scheme)
        super("`#{scheme}' is not a supported db scheme")
      end
    end
  end
end
