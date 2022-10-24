# frozen_string_literal: true

require_relative "../context"

module Hanami
  module CLI
    module Generators
      module App
        class SliceContext < Generators::Context
          def initialize(inflector, app, slice, url)
            @slice = slice
            @url = url
            super(inflector, app)
          end

          def camelized_slice_name
            inflector.camelize(slice)
          end

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
