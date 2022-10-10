# frozen_string_literal: true

module Hanami
  module CLI
    class Files < Dry::Files
      def initialize(out: $stdout, **args)
        super(**args)
        @out = out
      end

      def write(path, *content)
        already_exists = exist?(path)
        super
        if already_exists
          updated(path)
        else
          created(path)
        end
      end

      def mkdir(path)
        unless exist?(path)
          super
          created("#{path}/")
        end
      end

      def chdir(path, &blk)
        within_folder(path)
        super
      end

      private

      attr_reader :out

      def updated(path)
        out.puts "Updated #{path}"
      end

      def created(path)
        out.puts "Created #{path}"
      end

      def within_folder(path)
        out.puts "-> Within #{path}/"
      end
    end
  end
end
