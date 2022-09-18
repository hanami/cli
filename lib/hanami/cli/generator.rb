module Hanami
  module CLI
    class Generator
      extend Forwardable

      def initialize(files:, out: $stdout)
        @files = files
        @out = out
      end

      def_delegators :files, :join, :mkdir, :directory?, :chdir

      def write(path, *content)
        if files.exist?(path)
          files.write(path, *content)
          out.puts "Updated #{path}"
        else
          files.write(path, *content)
          out.puts "Created #{path}"
        end
      end

      def inject_line_at_block_bottom(path, target, *contents)
        files.inject_line_at_block_bottom(path, target, *contents)
        out.puts "Updated #{path}. Added `#{contents.first}` #{ "(and #{ contents.length - 1} more lines)" if contents.length > 1 }"
      end

      def inject_line_at_class_bottom(path, target, *contents)
        files.inject_line_at_class_bottom(path, target, *contents)
        out.puts "Updated #{path}. Added `#{contents.first}` #{ "(and #{ contents.length - 1} more lines)" if contents.length > 1 }"
      end

      private

      attr_reader :files, :out
    end
  end
end
