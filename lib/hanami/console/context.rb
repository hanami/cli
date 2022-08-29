# frozen_string_literal: true

require_relative "plugins/slice_readers"

module Hanami
  module Console
    # Hanami app console context
    #
    # @api private
    # @since 2.0.0
    class Context < Module
      # @api private
      attr_reader :app

      # @api private
      def initialize(app)
        super()
        @app = app

        define_context_methods
        include Plugins::SliceReaders.new(app)
      end

      private

      def define_context_methods
        hanami_app = app

        define_method(:inspect) do
          "#<#{self.class} app=#{hanami_app} env=#{hanami_app.config.env}>"
        end

        define_method(:app) do
          hanami_app
        end

        define_method(:reload) do
          puts "Reloading..."
          Kernel.exec("#{$PROGRAM_NAME} console")
        end

        define_method(:method_missing) do |name, *args, &block|
          return hanami_app.public_send(name, *args, &block) if hanami_app.respond_to?(name)

          super(name, *args, &block)
        end

        define_method(:respond_to_missing?) do |name, include_private|
          super(name, include_private) || hanami_app.respond_to?(name, include_private)
        end
      end
    end
  end
end
