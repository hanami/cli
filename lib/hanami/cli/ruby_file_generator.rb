# frozen_string_literal: true

require "prism"

module Hanami
  module CLI
    class RubyFileGenerator

      class InvalidInstanceVariablesError < Error
        def initialize
        end
      end

      class DuplicateInitializeMethodError < Error
        def initialize
          super("Initialize method cannot be defined if instance variables are present")
        end
      end

      class GeneratedUnparseableCodeError < Error
        def initialize(source_code)
          super(
            <<~ERROR_MESSAGE
              Sorry, the code we generated is not valid Ruby.

              Here's what we got:

              #{source_code}

              Please fix the errors and try again.
            ERROR_MESSAGE
          )
        end
      end
      INDENT = "  "

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        class_name: nil,
        parent_class: nil,
        modules: [],
        requires: [],
        relative_requires: [],
        methods: {},
        includes: [],
        top_contents: [],
        magic_comments: {},
        ivars: []
      )
        @class_name = class_name
        @parent_class = parent_class
        @modules = modules
        @requires = requires
        @relative_requires = relative_requires
        @methods = methods
        @includes = includes
        @top_contents = top_contents
        @magic_comments = magic_comments.merge(frozen_string_literal).compact.sort
        @ivar_names = parse_ivar_names!(ivars)

        raise DuplicateInitializeMethodError if methods.key?(:initialize) && ivars.any?
      end
      # rubocop:enable Metrics/ParameterLists

      def self.class(class_name, **)
        new(class_name: class_name, **).to_s
      end

      def self.module(*names, **)
        module_names = if names.first.is_a?(Array)
                        names.first
                      else
                        names
                      end

        new(modules: module_names, class_name: nil, parent_class: nil, **).to_s
      end

      def to_s
        definition = lines(modules).map { |line| "#{line}\n" }.join

        source_code = [file_directives, definition].flatten.join("\n")

        ensure_parseable!(source_code)
      end


      private

      attr_reader(
        :class_name,
        :parent_class,
        :modules,
        :requires,
        :relative_requires,
        :methods,
        :includes,
        :top_contents,
        :magic_comments,
        :ivar_names
      )

      def lines(remaining_modules)
        this_module, *rest_modules = remaining_modules
        if this_module
          with_module_lines(this_module, lines(rest_modules))
        elsif class_name
          class_lines
        else
          []
        end
      end

      def with_module_lines(module_name, contents_lines)
        [
          "module #{module_name}",
          *contents_lines.map { |line| indent(line) },
          "end"
        ]
      end

      def file_directives
        [magic_comments_lines, import_lines].compact
      end

      def magic_comments_lines
        lines = magic_comments
          .map { |magic_key, magic_value| "# #{magic_key}: #{magic_value}" }
        add_empty_line_if_any(lines)
      end

      def frozen_string_literal
        {frozen_string_literal: true}
      end

      def import_lines
        lines = [requires_lines, relative_requires_lines].flatten.compact
        add_empty_line_if_any(lines)
      end

      def requires_lines
        requires.map do |require|
          %(require "#{require}")
        end
      end

      def relative_requires_lines
        relative_requires.map do |require|
          %(require_relative "#{require}")
        end
      end

      def class_lines
        if class_name
          [
            class_definition,
            *class_contents_lines,
            "end"
          ].compact
        else
          []
        end
      end

      def includes_lines
        if includes.any?
          includes.map do |include|
            "include #{include}"
          end
        end
      end

      def top_contents_lines
        if top_contents.any?
          top_contents
        end
      end

      def class_contents_lines
        line_groups = [
          includes_lines,
          top_contents_lines,
          initialize_lines,
          *methods_lines,
          *private_contents_lines
        ].compact
        add_empty_line_between_groups(line_groups).flatten.map { |line| indent(line) }
      end

      def initialize_lines
        if ivar_names.any?
          [
            method_definition("initialize", ivar_names.map { |ivar| "#{ivar}:" }),
            ivar_names.map { |ivar_name| indent("@#{ivar_name} = #{ivar_name}") }.flatten,
            "end"
          ]
        end
      end

      def private_contents_lines
        if ivar_names.any?
          [
            "private",
            "attr_reader #{ivar_names.map { |ivar| ":#{ivar}" }.join(', ')}"
          ]
        end
      end

      def methods_lines
        methods.map do |method_name, args|
          [method_definition(method_name, args), "end"]
        end
      end

      def class_definition
        if parent_class
          "class #{class_name} < #{parent_class}"
        else
          "class #{class_name}"
        end
      end

      def method_definition(method_name, args)
        if args
          "def #{method_name}(#{args.join(', ')})"
        else
          "def #{method_name}"
        end
      end

      def indent(line)
        if line.strip.empty?
          ""
        else
          INDENT + line
        end
      end

      def parse_ivar_names!(ivars)
        if ivars.all? { |ivar| ivar.start_with?("@") }
          ivars.map { |ivar| ivar.to_s.delete_prefix("@") }
        else
          raise InvalidInstanceVariablesError
        end
      end

      def ensure_parseable!(source_code)
        parse_result = Prism.parse(source_code)

        if parse_result.success?
          source_code
        else
          raise GeneratedUnparseableCodeError.new(source_code)
        end
      end

      def add_empty_line_if_any(lines)
        if lines.any?
          lines << ""
        end
      end

      def add_empty_line_between_groups(line_groups)
        # We add an empty line after every group then remove the last one
        line_groups.flat_map { |line_group| [line_group, ""] }[0...-1]
      end
    end
  end
end
