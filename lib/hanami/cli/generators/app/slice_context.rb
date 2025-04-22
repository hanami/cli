# frozen_string_literal: true

require_relative "../context"
require_relative "../constants"

module Hanami
  module CLI
    module Generators
      module App
        # @since 2.0.0
        # @api private
        class SliceContext < Generators::Context
          # @since 2.0.0
          # @api private
          def initialize(inflector, app, slice, url, **options)
            @slice = slice
            @url = url
            super(inflector, app, **options)
          end

          # @since 2.1.0
          # @api private
          def humanized_slice_name
            inflector.humanize(slice)
          end

          private

          attr_reader :slice

          attr_reader :url
        end
      end
    end
  end
end
