# frozen_string_literal: true

require "dry/files"

module Hanami
  module CLI
    # @since 2.0.0
    # @api private
    class Files < Dry::Files
      # @since 2.0.0
      # @api private
      def initialize(out: $stdout, **args)
        super(**args)
        @out = out
      end

      # @since 2.0.0
      # @api private
      def write(path, *content)
        already_exists = exist?(path)

        # delete .keep files unless running `hanami new`
        base = path.split('/')[0]
        keepfile = Dir.glob('**/.keep', base:)

        if caller_locations(1,1)[0].label != 'generate_app' && keepfile.any? && exist?("#{base}/#{keepfile[0]}")
          delete("#{base}/#{keepfile[0]}")
        end

        super
        if already_exists
          updated(path)
        else
          created(path)
        end
      end

      # @since 2.0.0
      # @api private
      def mkdir(path)
        unless exist?(path)
          super
          created(_path(path))
        end
      end

      # @since 2.0.0
      # @api private
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
        out.puts "-> Within #{_path(path)}"
      end

      def _path(path)
        path + ::File::SEPARATOR
      end
    end
  end
end
