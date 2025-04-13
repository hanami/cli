# frozen_string_literal: true

module Hanami
  module CLI
    # Module that provides functionality to detect the current slice based on the PWD directory
    # @api private
    module SliceDetection
      # Detects if the current directory is a slice directory or the app directory
      # and returns the slice name if in a slice directory, nil otherwise.
      #
      # @return [String, nil] the slice name if in a slice directory, nil otherwise
      #
      # @api private
      def detect_slice_from_current_directory
        current_dir = Pathname.new(Dir.pwd)
        app_root = app.root
        return nil if current_dir == app_root.join("app")

        slices_dir = app_root.join("slices")
        if current_dir.to_s.start_with?(slices_dir.to_s)
          relative_path = current_dir.relative_path_from(slices_dir)
          slice_name = relative_path.to_s.split("/").first

          return slice_name if app.slices[slice_name.to_sym]
        end

        nil
      end
    end
  end
end
