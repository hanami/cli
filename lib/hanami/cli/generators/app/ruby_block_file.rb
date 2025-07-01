# frozen_string_literal: true

require_relative "../constants"
require_relative "ruby_file"

module Hanami
  module CLI
    module Generators
      module App
        # @since x.x.x
        # @api private
        class RubyBlockFile < RubyFile
          def initialize(signature:, **args)
            raise ArgumentError, "`signature` is required" unless signature

            super

            @signature = signature
          end

          def contents
            RubyFileGenerator.new(
              headers: headers,
              body: body,
              modules: modules,
              block_signature: signature
            ).call
          end

          private

          attr_reader :signature

          def modules
            namespace_modules
          end
        end
      end
    end
  end
end