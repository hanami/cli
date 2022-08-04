# frozen_string_literal: true

require "hanami"
require "hanami/cli/commands/app/generate/action"
require "ostruct"

RSpec.describe Hanami::CLI::Commands::App::Generate::Action do
  subject { described_class.new(fs: fs, inflector: inflector, generator: generator) }

  let(:fs) { Dry::Files.new(memory: true) }
  let(:inflector) { Dry::Inflector.new }
  let(:generator) { Hanami::CLI::Generators::App::Action.new(fs: fs, inflector: inflector) }
  let(:app) { "Bookshelf" }
  let(:dir) { inflector.underscore(app) }
  let(:controller) { "users" }
  let(:action) { "index" }
  let(:action_name) { "#{controller}.#{action}" }

  context "generate for app" do
    it "generates action" do
      within_application_directory do
        subject.call(name: action_name)

        # Route
        routes = <<~CODE
          # frozen_string_literal: true

          require "hanami/routes"

          module #{app}
            class Routes < Hanami::Routes
              define do
                root { "Hello from Hanami" }
                get "/users", to: "users.index"
              end
            end
          end
        CODE

        # route
        expect(fs.read("config/routes.rb")).to eq(routes)

        action_file = <<~EXPECTED
          # frozen_string_literal: true

          require "#{inflector.underscore(app)}/action"

          module #{inflector.classify(app)}
            module Actions
              module #{inflector.camelize(controller)}
                class #{inflector.classify(action)} < #{inflector.classify(app)}::Action
                end
              end
            end
          end
        EXPECTED
        expect(fs.read("app/actions/#{controller}/#{action}.rb")).to eq(action_file)

        # # view
        # view_file = <<~EXPECTED
        #   # auto_register: false
        #   # frozen_string_literal: true
        #
        #   require "#{inflector.underscore(slice)}/view"
        #
        #   module #{inflector.classify(slice)}
        #     module Views
        #       module #{inflector.camelize(controller)}
        #         class #{inflector.classify(action)} < #{inflector.classify(slice)}::View
        #         end
        #       end
        #     end
        #   end
        # EXPECTED
        # expect(fs.read("slices/#{slice}/views/#{controller}/#{action}.rb")).to eq(view_file)

        # template
        # expect(fs.directory?("slices/#{slice}/templates/#{controller}")).to be(true)
        #
        # template_file = <<~EXPECTED
        #   <h1>#{inflector.classify(slice)}::Views::#{inflector.camelize(controller)}::#{inflector.classify(action)}</h1>
        #   <h2>slices/#{slice}/templates/#{controller}/#{action}.html.erb</h2>
        # EXPECTED
        # expect(fs.read("slices/#{slice}/templates/#{controller}/#{action}.html.erb")).to eq(template_file)
      end
    end

    it "raises error if action name doesn't respect the convention" do
      expect {
        subject.call(name: "foo")
      }.to raise_error(ArgumentError, "cannot parse controller and action name: `foo'\n\texample: users.show")
    end

    it "raises error if HTTP method is unknown" do
      expect {
        subject.call(name: action_name, http: "foo")
      }.to raise_error(ArgumentError, "unknown HTTP method: `foo'")
    end

    it "raises error if URL is invalid" do
      expect {
        subject.call(name: action_name, url: "//")
      }.to raise_error(ArgumentError, "invalid URL: `//'")
    end

    it "infers RESTful action URL and HTTP method for routes" do
      within_application_directory do
        subject.call(name: "users.index")
        expect(fs.read("config/routes.rb")).to match(%(get "/users", to: "users.index"))

        subject.call(name: "users.new")
        expect(fs.read("config/routes.rb")).to match(%(get "/users/new", to: "users.new"))

        subject.call(name: "users.create")
        expect(fs.read("config/routes.rb")).to match(%(post "/users", to: "users.create"))

        subject.call(name: "users.edit")
        expect(fs.read("config/routes.rb")).to match(%(get "/users/:id/edit", to: "users.edit"))

        subject.call(name: "users.update")
        expect(fs.read("config/routes.rb")).to match(%(patch "/users/:id", to: "users.update"))

        subject.call(name: "users.show")
        expect(fs.read("config/routes.rb")).to match(%(get "/users/:id", to: "users.show"))

        subject.call(name: "users.destroy")
        expect(fs.read("config/routes.rb")).to match(%(delete "/users/:id", to: "users.destroy"))
      end
    end

    it "allows to specify action URL" do
      within_application_directory do
        subject.call(name: action_name, url: "/people")
        expect(fs.read("config/routes.rb")).to match(%(get "/people", to: "users.index"))
      end
    end

    it "allows to specify action HTTP method" do
      within_application_directory do
        subject.call(name: action_name, http: "put")
        expect(fs.read("config/routes.rb")).to match(%(put "/users", to: "users.index"))
      end
    end

    xit "allows to specify MIME Type for template" do
      within_application_directory do
        subject.call(name: action_name, format: format = "json")

        expect(fs.exist?("app/actions/#{controller}/#{action}.rb")).to be(true)
        expect(fs.exist?("app/views/#{controller}/#{action}.rb")).to be(true)

        # template
        template_file = <<~EXPECTED
        EXPECTED
        expect(fs.read("app/templates/#{controller}/#{action}.#{format}.erb")).to eq(template_file)
      end
    end

    xit "can skip view creation" do
      within_application_directory do
        subject.call(name: action_name, skip_view: true)

        expect(fs.exist?("app/actions/#{controller}/#{action}.rb")).to be(true)

        expect(fs.exist?("app/views/#{controller}/#{action}.rb")).to be(false)
        expect(fs.exist?("app/templates/#{controller}/#{action}.html.erb")).to be(false)
      end
    end
  end

  context "generate for a slice" do
    let(:slice) { "main" }

    before { prepare_slice! }

    it "generates action" do
      within_application_directory do
        prepare_slice!

        subject.call(name: action_name, slice: slice)

        # Route
        routes = <<~CODE
          # frozen_string_literal: true

          require "hanami/routes"

          module #{app}
            class Routes < Hanami::Routes
              define do
                root { "Hello from Hanami" }

                slice :#{slice}, at: "/#{slice}" do
                  get "/users", to: "users.index"
                end
              end
            end
          end
        CODE

        # route
        expect(fs.read("config/routes.rb")).to eq(routes)

        # action
        expect(fs.directory?("slices/#{slice}/actions/#{controller}")).to be(true)

        action_file = <<~EXPECTED
          # frozen_string_literal: true

          require "#{inflector.underscore(slice)}/action"

          module #{inflector.classify(slice)}
            module Actions
              module #{inflector.camelize(controller)}
                class #{inflector.classify(action)} < #{inflector.classify(slice)}::Action
                end
              end
            end
          end
        EXPECTED
        expect(fs.read("slices/#{slice}/actions/#{controller}/#{action}.rb")).to eq(action_file)

        # # view
        # expect(fs.directory?("slices/#{slice}/views/#{controller}")).to be(true)
        #
        # view_file = <<~EXPECTED
        #   # auto_register: false
        #   # frozen_string_literal: true
        #
        #   require "#{inflector.underscore(slice)}/view"
        #
        #   module #{inflector.classify(slice)}
        #     module Views
        #       module #{inflector.camelize(controller)}
        #         class #{inflector.classify(action)} < #{inflector.classify(slice)}::View
        #         end
        #       end
        #     end
        #   end
        # EXPECTED
        # expect(fs.read("slices/#{slice}/views/#{controller}/#{action}.rb")).to eq(view_file)

        # template
        # expect(fs.directory?("slices/#{slice}/templates/#{controller}")).to be(true)
        #
        # template_file = <<~EXPECTED
        #   <h1>#{inflector.classify(slice)}::Views::#{inflector.camelize(controller)}::#{inflector.classify(action)}</h1>
        #   <h2>slices/#{slice}/templates/#{controller}/#{action}.html.erb</h2>
        # EXPECTED
        # expect(fs.read("slices/#{slice}/templates/#{controller}/#{action}.html.erb")).to eq(template_file)
      end
    end

    context "deeply nested action" do
      let(:controller) { %w[books bestsellers nonfiction] }
      let(:controller_name) { controller.join(".") }
      let(:action) { "index" }
      let(:action_name) { "#{controller_name}.#{action}" }

      it "generates action" do
        within_application_directory do
          prepare_slice!

          subject.call(slice: slice, name: action_name)

          # Route
          routes = <<~CODE
            # frozen_string_literal: true

            require "hanami/routes"

            module #{app}
              class Routes < Hanami::Routes
                define do
                  root { "Hello from Hanami" }

                  slice :#{slice}, at: "/#{slice}" do
                    get "/books/bestsellers/nonfiction", to: "books.bestsellers.nonfiction.index"
                  end
                end
              end
            end
          CODE

          # route
          expect(fs.read("config/routes.rb")).to eq(routes)

          # action
          expect(fs.directory?("slices/#{slice}/actions/books/bestsellers/nonfiction")).to be(true)

          action_file = <<~EXPECTED
            # frozen_string_literal: true

            require "#{inflector.underscore(slice)}/action"

            module #{inflector.classify(slice)}
              module Actions
                module Books
                  module Bestsellers
                    module Nonfiction
                      class #{inflector.classify(action)} < #{inflector.classify(slice)}::Action
                      end
                    end
                  end
                end
              end
            end
          EXPECTED
          expect(fs.read("slices/#{slice}/actions/books/bestsellers/nonfiction/#{action}.rb")).to eq(action_file)

          # # view
          # expect(fs.directory?("slices/#{slice}/views/books/bestsellers/nonfiction")).to be(true)
          #
          # view_file = <<~EXPECTED
          #   # auto_register: false
          #   # frozen_string_literal: true
          #
          #   require "#{inflector.underscore(slice)}/view"
          #
          #   module #{inflector.classify(slice)}
          #     module Views
          #       module Books
          #         module Bestsellers
          #           module Nonfiction
          #             class #{inflector.classify(action)} < #{inflector.classify(slice)}::View
          #             end
          #           end
          #         end
          #       end
          #     end
          #   end
          # EXPECTED
          # expect(fs.read("slices/#{slice}/views/books/bestsellers/nonfiction/#{action}.rb")).to eq(view_file)

          # # template
          # expect(fs.directory?("slices/#{slice}/templates/books/bestsellers/nonfiction")).to be(true)
          #
          # template_file = <<~EXPECTED
          #   <h1>#{inflector.classify(slice)}::Views::Books::Bestsellers::Nonfiction::Index</h1>
          #   <h2>slices/#{slice}/templates/books/bestsellers/nonfiction/#{action}.html.erb</h2>
          # EXPECTED
          # expect(fs.read("slices/#{slice}/templates/books/bestsellers/nonfiction/#{action}.html.erb")).to eq(template_file)
        end
      end
    end

    it "appends routes within the proper slice block" do
      within_application_directory do
        prepare_slice!
        fs.mkdir("slices/api")

        routes_contents = <<~CODE
          # frozen_string_literal: true

          require "hanami/routes"

          module #{app}
            class Routes < Hanami::Routes
              define do
                root { "Hello from Hanami" }

                slice :#{slice}, at: "/#{slice}" do
                  root to: "home.index"
                end

                slice :api, at: "/api" do
                  root to: "home.index"
                end
              end
            end
          end
        CODE
        fs.write("config/routes.rb", routes_contents)

        expected = <<~CODE
          # frozen_string_literal: true

          require "hanami/routes"

          module #{app}
            class Routes < Hanami::Routes
              define do
                root { "Hello from Hanami" }

                slice :#{slice}, at: "/#{slice}" do
                  root to: "home.index"
                  get "/users", to: "users.index"
                end

                slice :api, at: "/api" do
                  root to: "home.index"
                  get "/users/:id", to: "users.show"
                end
              end
            end
          end
        CODE

        subject.call(slice: slice, name: "users.index")
        subject.call(slice: "api", name: "users.show")

        expect(fs.read("config/routes.rb")).to eq(expected)
      end
    end

    it "raises error if slice is unexisting" do
      expect { subject.call(slice: "foo", name: action_name) }.to raise_error(ArgumentError, "slice not found `foo'")
    end
  end

  private

  def within_application_directory
    application = Struct.new(:namespace).new(app)

    allow(Hanami).to receive(:app)
      .and_return(application)

    fs.mkdir(dir)
    fs.chdir(dir) do
      routes = <<~CODE
        # frozen_string_literal: true

        require "hanami/routes"

        module #{app}
          class Routes < Hanami::Routes
            define do
              root { "Hello from Hanami" }
            end
          end
        end
      CODE

      fs.write("config/routes.rb", routes)

      yield
    end
  end

  def prepare_slice!
    fs.mkdir("slices/#{slice}")
    routes = <<~CODE
      # frozen_string_literal: true

      require "hanami/routes"

      module #{app}
        class Routes < Hanami::Routes
          define do
            root { "Hello from Hanami" }

            slice :#{slice}, at: "/#{slice}" do
            end
          end
        end
      end
    CODE

    fs.write("config/routes.rb", routes)
  end
end
