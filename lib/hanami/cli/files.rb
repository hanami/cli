# frozen_string_literal: true

module Hanami
  module CLI
    class Files < Dry::Files
      def initialize(out: $stdout, **args)
        super(**args)
        @out = out
      end

      def write(path, *content)
        if exist?(path)
          super
          updated(path)
        else
          super
          created(path)
        end
      end

      def inject_line_at_block_bottom(path, target, contents)
        super
        updated(path)
      end

      def inject_line_at_class_bottom(path, target, contents)
        super
        updated(path)
      end

      def mkdir(path)
        unless exist?(path)
          super
          created("#{path}/")
        end
      end

      private

      attr_reader :out

      def updated(path)
        out.puts "Updated #{path}"
      end

      def created(path)
        out.puts "Created #{path}"
      end
    end
  end
end
