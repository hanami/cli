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
          application.slices.each do |(name, slice)|
            define_method(name) do
              slice
            end
          end
        end
      end
    end
  end
end
