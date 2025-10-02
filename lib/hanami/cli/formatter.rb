# frozen_string_literal: true

module Hanami
  module CLI
    # Provides formatting utilities for CLI output including colors and icons
    #
    # @api private
    # @since 2.3.0
    module Formatter
      # ANSI color codes
      COLORS = {
        reset: "\e[0m",
        bold: "\e[1m",
        green: "\e[32m",
        blue: "\e[34m",
        cyan: "\e[36m",
        yellow: "\e[33m",
        red: "\e[31m",
        gray: "\e[90m"
      }.freeze

      # Icons for different operations
      ICONS = {
        create: "✓",
        update: "↻",
        info: "→",
        warning: "⚠",
        error: "✗",
        success: "✓"
      }.freeze

      module_function

      # Wraps text in color codes
      #
      # @param text [String] the text to colorize
      # @param color [Symbol] the color name from COLORS
      # @return [String] colorized text
      #
      # @api private
      def colorize(text, color)
        return text unless $stdout.tty?

        "#{COLORS[color]}#{text}#{COLORS[:reset]}"
      end

      # Formats a create message
      #
      # @param path [String] the path that was created
      # @return [String] formatted message
      #
      # @api private
      def created(path)
        icon = colorize(ICONS[:create], :green)
        label = colorize("create", :green)
        "  #{icon} #{label}  #{path}"
      end

      # Formats a create directory message
      #
      # @param path [String] the directory path that was created
      # @return [String] formatted message
      #
      # @api private
      def created_directory(path)
        icon = colorize(ICONS[:create], :green)
        label = colorize("create directory", :green)
        "#{icon} #{label}  #{path}"
      end

      # Formats an update message
      #
      # @param path [String] the path that was updated
      # @return [String] formatted message
      #
      # @api private
      def updated(path)
        icon = colorize(ICONS[:update], :cyan)
        label = colorize("update", :cyan)
        "  #{icon} #{label}  #{path}"
      end

      # Formats an info message
      #
      # @param text [String] the message text
      # @return [String] formatted message
      #
      # @api private
      def info(text)
        icon = colorize(ICONS[:info], :blue)
        "#{icon} #{text}"
      end

      # Formats a success message
      #
      # @param text [String] the message text
      # @return [String] formatted message
      #
      # @api private
      def success(text)
        icon = colorize(ICONS[:success], :green)
        label = colorize("✓", :green)
        "#{label} #{colorize(text, :green)}"
      end

      # Formats a warning message
      #
      # @param text [String] the message text
      # @return [String] formatted message
      #
      # @api private
      def warning(text)
        icon = colorize(ICONS[:warning], :yellow)
        label = colorize("warning", :yellow)
        "#{icon} #{label} #{text}"
      end

      # Formats an error message
      #
      # @param text [String] the message text
      # @return [String] formatted message
      #
      # @api private
      def error(text)
        icon = colorize(ICONS[:error], :red)
        label = colorize("error", :red)
        "#{icon} #{label} #{text}"
      end

      # Formats a section header
      #
      # @param text [String] the header text
      # @return [String] formatted header
      #
      # @api private
      def header(text)
        "\n#{colorize(text, :bold)}"
      end

      # Formats a dim/secondary text
      #
      # @param text [String] the text to dim
      # @return [String] formatted text
      #
      # @api private
      def dim(text)
        text # No special dim color, just return plain text for now
      end
    end
  end
end
