# frozen_string_literal: true

require_relative "plugins/slice_readers"

module Hanami
  module Console
    # Hanami application console context
    #
    # @api private
    # @since 2.0.0
    class Context < Module
      # @api private
      def initialize(application)
        @application = application
      end

      # @api private
      def extended(other)
        super
        app = @application

        extend(Plugins::SliceReaders.new(app))

        define_method(:inspect) do
          "#<#{self.class} application=#{app} env=#{app.config.env}>"
        end

        define_method(:method_missing) do |name, *args, &block|
          return app.public_send(name, *args, &block) if app.respond_to?(name)
          super(name, *args, &block)
        end

        define_method(:respond_to_missing?) do |name, include_private|
          super(name, include_private) || app.respond_to?(name, include_private)
        end
      end
    end
  end
end
