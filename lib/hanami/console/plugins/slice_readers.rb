# frozen_string_literal: true

require "delegate"

module Hanami
  module Console
    module Plugins
      # @api private
      # @since 2.0.0
      class SliceReaders < Module
        # @api private
        def initialize(application)
          super()

          application.slices.each do |slice|
            define_method(slice.slice_name) do
              slice
            end
          end
        end
      end
    end
  end
end
