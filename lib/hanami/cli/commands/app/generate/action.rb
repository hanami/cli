# frozen_string_literal: true

require "dry/inflector"
require "dry/files"
require "shellwords"
require_relative "../../../naming"
require_relative "../../../errors"

module Hanami
  module CLI
    module Commands
      module App
        module Generate
          # @since 2.0.0
          # @api private
          class Action < App::Command
            # TODO: ideally the default format should lookup
            #       slice configuration (Action's `default_response_format`)
            DEFAULT_FORMAT = "html"
            private_constant :DEFAULT_FORMAT

            DEFAULT_SKIP_VIEW = false
            private_constant :DEFAULT_SKIP_VIEW

            DEFAULT_SKIP_TESTS = false
            private_constant :DEFAULT_SKIP_TESTS

            DEFAULT_SKIP_ROUTE = false
            private_constant :DEFAULT_SKIP_ROUTE

            DEFAULT_TEMPLATE = "erb"
            private_constant :DEFAULT_TEMPLATE

            argument :name, required: true, desc: "Action name"
            option :url, required: false, type: :string, desc: "Action URL"
            option :http, required: false, type: :string, desc: "Action HTTP method"
            # option :format, required: false, type: :string, default: DEFAULT_FORMAT, desc: "Template format"
            option \
              :skip_view,
              required: false,
              type: :flag,
              default: DEFAULT_SKIP_VIEW,
              desc: "Skip view and template generation"
            option \
              :skip_tests,
              required: false,
              type: :flag,
              default: DEFAULT_SKIP_TESTS,
              desc: "Skip test generation"
            option \
              :skip_route,
              required: false,
              type: :flag,
              default: DEFAULT_SKIP_ROUTE,
              desc: "Skip route generation"
            option :slice, required: false, desc: "Slice name"
            option :template, required: false, type: :string, default: DEFAULT_TEMPLATE,
                              desc: "Template engine to use (officially supported options: erb, haml, slim)"

            # rubocop:disable Layout/LineLength
            example [
              %(books.index               # GET    /books          to: "books.index"    (MyApp::Actions::Books::Index)),
              %(books.new                 # GET    /books/new      to: "books.new"      (MyApp::Actions::Books::New)),
              %(books.create              # POST   /books          to: "books.create"   (MyApp::Actions::Books::Create)),
              %(books.edit                # GET    /books/:id/edit to: "books.edit"     (MyApp::Actions::Books::Edit)),
              %(books.update              # PATCH  /books/:id      to: "books.update"   (MyApp::Actions::Books::Update)),
              %(books.show                # GET    /books/:id      to: "books.show"     (MyApp::Actions::Books::Show)),
              %(books.destroy             # DELETE /books/:id      to: "books.destroy"  (MyApp::Actions::Books::Destroy)),
              %(books.sale                # GET    /books/sale     to: "books.sale"     (MyApp::Actions::Books::Sale)),
              %(sessions.new --url=/login # GET    /login          to: "sessions.new"   (MyApp::Actions::Sessions::New)),
              %(authors.update --http=put # PUT    /authors/:id    to: "authors.update" (MyApp::Actions::Authors::Update)),
              %(users.index --slice=admin # GET    /admin/users    to: "users.index"    (Admin::Actions::Users::Update))
            ]
            # rubocop:enable Layout/LineLength

            # @since 2.0.0
            # @api private
            def initialize(
              fs:, inflector:,
              naming: Naming.new(inflector: inflector),
              generator: Generators::App::Action.new(fs: fs, inflector: inflector),
              **opts
            )
              super(fs: fs, inflector: inflector, **opts)

              @naming = naming
              @generator = generator
            end

            # rubocop:disable Metrics/ParameterLists

            # @since 2.0.0
            # @api private
            def call(
              name:,
              url: nil,
              http: nil,
              format: DEFAULT_FORMAT,
              skip_view: DEFAULT_SKIP_VIEW,
              skip_tests: DEFAULT_SKIP_TESTS, # rubocop:disable Lint/UnusedMethodArgument,
              skip_route: DEFAULT_SKIP_ROUTE,
              template: DEFAULT_TEMPLATE,
              slice: nil,
              context: nil,
              **
            )
              slice = inflector.underscore(Shellwords.shellescape(slice)) if slice
              name = naming.action_name(name)
              *controller, action = name.split(ACTION_SEPARATOR)

              if controller.empty?
                raise InvalidActionNameError.new(name)
              end

              generator.call(app.namespace, controller, action, url, http, format, skip_view, skip_route, template, slice,
                             context: context)
            end

            # rubocop:enable Metrics/ParameterLists

            private

            attr_reader :naming, :generator
          end
        end
      end
    end
  end
end
