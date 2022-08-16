# frozen_string_literal: true

require "hanami/cli/commands/app/generate/action"
require "ostruct"

RSpec.describe Hanami::CLI::Commands::App::Generate::Action do
  subject { described_class.new(fs: fs, inflector: inflector, generator: generator) }

  let(:fs) { Dry::Files.new(memory: true) }
  let(:inflector) { Dry::Inflector.new }
  let(:generator) { Hanami::CLI::Generators::App::Action.new(fs: fs, inflector: inflector) }
  let(:app) { "Bookshelf" }
  let(:slice) { "main" }
  let(:controller) { "users" }
  let(:action) { "index" }
  let(:action_name) { "#{controller}.#{action}" }

  before { prepare_slice! }

  it "generates action" do
    subject.call(slice: slice, name: action_name)

    # route
    expect(fs.read("config/routes.rb")).to match(%(get "/users", to: "users.index"))

    # action
    expect(fs.directory?(directory = "slices/#{slice}/actions/#{controller}")).to be(true)

    fs.chdir(directory) do
      action_file = <<~EXPECTED
        # auto_register: false
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
      expect(fs.read("#{action}.rb")).to eq(action_file)
    end

    # view
    expect(fs.directory?(directory = "slices/#{slice}/views/#{controller}")).to be(true)

    fs.chdir(directory) do
      view_file = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "#{inflector.underscore(slice)}/view"

        module #{inflector.classify(slice)}
          module Views
            module #{inflector.camelize(controller)}
              class #{inflector.classify(action)} < #{inflector.classify(slice)}::View
              end
            end
          end
        end
      EXPECTED
      expect(fs.read("#{action}.rb")).to eq(view_file)
    end

    # template
    expect(fs.directory?(directory = "slices/#{slice}/templates/#{controller}")).to be(true)

    fs.chdir(directory) do
      template_file = <<~EXPECTED
        <h1>#{inflector.classify(slice)}::Views::#{inflector.camelize(controller)}::#{inflector.classify(action)}</h1>
        <h2>slices/#{slice}/templates/#{controller}/#{action}.html.erb</h2>
      EXPECTED
      expect(fs.read("#{action}.html.erb")).to eq(template_file)
    end
  end

  context "deeply nested action" do
    let(:controller) { %w[books bestsellers nonfiction] }
    let(:controller_name) { controller.join(".") }
    let(:action) { "index" }
    let(:action_name) { "#{controller_name}.#{action}" }

    it "generates action" do
      subject.call(slice: slice, name: action_name)

      # route
      expect(fs.read("config/routes.rb")).to match(
        %(get "/books/bestsellers/nonfiction", to: "books.bestsellers.nonfiction.index")
      )

      # action
      expect(fs.directory?(directory = "slices/#{slice}/actions/books/bestsellers/nonfiction")).to be(true)

      fs.chdir(directory) do
        action_file = <<~EXPECTED
          # auto_register: false
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
        expect(fs.read("#{action}.rb")).to eq(action_file)
      end

      # view
      expect(fs.directory?(directory = "slices/#{slice}/views/books/bestsellers/nonfiction")).to be(true)

      fs.chdir(directory) do
        view_file = <<~EXPECTED
          # auto_register: false
          # frozen_string_literal: true

          require "#{inflector.underscore(slice)}/view"

          module #{inflector.classify(slice)}
            module Views
              module Books
                module Bestsellers
                  module Nonfiction
                    class #{inflector.classify(action)} < #{inflector.classify(slice)}::View
                    end
                  end
                end
              end
            end
          end
        EXPECTED
        expect(fs.read("#{action}.rb")).to eq(view_file)
      end

      # template
      expect(fs.directory?(directory = "slices/#{slice}/templates/books/bestsellers/nonfiction")).to be(true)

      fs.chdir(directory) do
        template_file = <<~EXPECTED
          <h1>#{inflector.classify(slice)}::Views::Books::Bestsellers::Nonfiction::Index</h1>
          <h2>slices/#{slice}/templates/books/bestsellers/nonfiction/#{action}.html.erb</h2>
        EXPECTED
        expect(fs.read("#{action}.html.erb")).to eq(template_file)
      end
    end
  end

  it "appends routes within the proper slice block" do
    fs.mkdir("slices/api")

    routes_contents = <<~CODE
      # frozen_string_literal: true

      Hanami.app.routes do
        slice :#{slice}, at: "/" do
          root to: "home.index"
        end

        slice :api, at: "/api" do
          root to: "home.index"
        end
      end
    CODE
    fs.write("config/routes.rb", routes_contents)

    expected = <<~CODE
      # frozen_string_literal: true

      Hanami.app.routes do
        slice :#{slice}, at: "/" do
          root to: "home.index"
          get "/users", to: "users.index"
        end

        slice :api, at: "/api" do
          root to: "home.index"
          get "/users/:id", to: "users.show"
        end
      end
    CODE

    subject.call(slice: slice, name: "users.index")
    subject.call(slice: "api", name: "users.show")
    expect(fs.read("config/routes.rb")).to eq(expected)
  end

  it "infers RESTful action URL and HTTP method for routes" do
    subject.call(slice: slice, name: "users.index")
    expect(fs.read("config/routes.rb")).to match(%(get "/users", to: "users.index"))

    subject.call(slice: slice, name: "users.new")
    expect(fs.read("config/routes.rb")).to match(%(get "/users/new", to: "users.new"))

    subject.call(slice: slice, name: "users.create")
    expect(fs.read("config/routes.rb")).to match(%(post "/users", to: "users.create"))

    subject.call(slice: slice, name: "users.edit")
    expect(fs.read("config/routes.rb")).to match(%(get "/users/:id/edit", to: "users.edit"))

    subject.call(slice: slice, name: "users.update")
    expect(fs.read("config/routes.rb")).to match(%(patch "/users/:id", to: "users.update"))

    subject.call(slice: slice, name: "users.show")
    expect(fs.read("config/routes.rb")).to match(%(get "/users/:id", to: "users.show"))

    subject.call(slice: slice, name: "users.destroy")
    expect(fs.read("config/routes.rb")).to match(%(delete "/users/:id", to: "users.destroy"))
  end

  it "allows to specify action URL" do
    subject.call(slice: slice, name: action_name, url: "/people")
    expect(fs.read("config/routes.rb")).to match(%(get "/people", to: "users.index"))
  end

  it "allows to specify action HTTP method" do
    subject.call(slice: slice, name: action_name, http: "put")
    expect(fs.read("config/routes.rb")).to match(%(put "/users", to: "users.index"))
  end

  it "allows to specify MIME Type for template" do
    subject.call(slice: slice, name: action_name, format: format = "json")

    fs.chdir("slices/#{slice}") do
      expect(fs.exist?("actions/#{controller}/#{action}.rb")).to be(true)
      expect(fs.exist?("views/#{controller}/#{action}.rb")).to be(true)

      # template
      expect(fs.exist?(file = "templates/#{controller}/#{action}.#{format}.erb")).to be(true)

      template_file = <<~EXPECTED
      EXPECTED
      expect(fs.read(file)).to eq(template_file)
    end
  end

  it "can skip view creation" do
    subject.call(slice: slice, name: action_name, skip_view: true)

    fs.chdir("slices/#{slice}") do
      expect(fs.exist?("actions/#{controller}/#{action}.rb")).to be(true)

      expect(fs.exist?("views/#{controller}/#{action}.rb")).to be(false)
      expect(fs.exist?("templates/#{controller}/#{action}.html.erb")).to be(false)
    end
  end

  it "raises error if slice is unexisting" do
    expect { subject.call(slice: "foo", name: action_name) }.to raise_error(ArgumentError, "slice not found `foo'")
  end

  it "raises error if action name doesn't respect the convention" do
    expect {
      subject.call(slice: slice, name: "foo")
    }.to raise_error(ArgumentError, "cannot parse controller and action name: `foo'\n\texample: users.show")
  end

  it "raises error if HTTP method is unknown" do
    expect {
      subject.call(slice: slice, name: action_name, http: "foo")
    }.to raise_error(ArgumentError, "unknown HTTP method: `foo'")
  end

  it "raises error if URL is invalid" do
    expect {
      subject.call(slice: slice, name: action_name, url: "//")
    }.to raise_error(ArgumentError, "invalid URL: `//'")
  end

  private

  def prepare_slice!
    fs.mkdir("slices/#{slice}")

    routes_contents = <<~CODE
      # frozen_string_literal: true

      Hanami.app.routes do
        slice :#{slice}, at: "/" do
        end
      end
    CODE
    fs.write("config/routes.rb", routes_contents)
  end
end
