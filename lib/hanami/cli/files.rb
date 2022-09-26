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
          out.puts "Updated #{path}"
        else
          super
          out.puts "Created #{path}"
        end
      end

      def inject_line_at_block_bottom(path, target, *contents)
        super
        out.puts "Updated #{path}. Added `#{contents.first}` #{"(and #{contents.length - 1} more lines)" if contents.length > 1}"
      end

      def inject_line_at_class_bottom(path, target, *contents)
        super
        out.puts "Updated #{path}. Added `#{contents.first}` #{"(and #{contents.length - 1} more lines)" if contents.length > 1}"
      end

      private

      attr_reader :out
    end
  end
end
