# frozen_string_literal: true

require_relative "../context"

module Hanami
  module CLI
    module Generators
      module Monolith
        class SliceContext < Generators::Context
          def initialize(inflector, app, slice)
            @slice = slice
            super(inflector, app)
          end

          def classified_slice_name
            inflector.classify(slice)
          end

          def underscored_slice_name
            inflector.underscore(slice)
          end

          private

          attr_reader :slice
        end
      end
    end
  end
end
