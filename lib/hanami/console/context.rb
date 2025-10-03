# frozen_string_literal: true

require_relative "plugins/slice_readers"

module Hanami
  # @since 2.0.0
  # @api private
  module Console
    # Hanami app console context
    #
    # @since 2.0.0
    # @api private
    class Context < Module
      attr_reader :app, :opts

      # @since 2.0.0
      # @api private
      def initialize(app, opts)
        super()
        @app = app
        @opts = opts

        define_context_methods
        boot_app if opts[:boot]
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

        # User-provided extension modules
        app.config.console.extensions.each do |mod|
          include mod
        end
      end

      def boot_app
        @app.boot
      end
    end
  end
end
