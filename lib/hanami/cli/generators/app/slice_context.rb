# frozen_string_literal: true

require_relative "../context"

module Hanami
  module CLI
    module Generators
      module App
        # @since 2.0.0
        # @api private
        class SliceContext < Generators::Context
          # @since 2.0.0
          # @api private
          def initialize(inflector, app, slice, url)
            @slice = slice
            @url = url
            super(inflector, app)
          end

          # @since 2.0.0
          # @api private
          def camelized_slice_name
            inflector.camelize(slice)
          end

          # @since 2.0.0
          # @api private
          def underscored_slice_name
            inflector.underscore(slice)
          end

          private

          attr_reader :slice

          attr_reader :url
        end
      end
    end
  end
end
