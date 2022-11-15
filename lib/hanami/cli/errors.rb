# frozen_string_literal: true

module Hanami
  module CLI
    class Error < StandardError
    end

    class MissingSliceError < Error
      def initialize(slice)
        super("slice `#{slice}' is missing, please generate with `hanami generate slice #{slice}'")
      end
    end
  end
end
