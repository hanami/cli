# frozen_string_literal: true

require "hanami"
require "securerandom"

RSpec.describe Hanami::CLI::Commands::App::Generate::Slice do
  subject { described_class.new(fs: fs, inflector: inflector, generator: generator) }

  before do
    allow(Hanami).to receive(:bundled?)
    allow(Hanami).to receive(:bundled?).with("hanami-assets").and_return(bundled_assets)
  end

  let(:out) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:generator) { Hanami::CLI::Generators::App::Slice.new(fs: fs, inflector: inflector) }
  let(:app) { "Bookshelf" }
  let(:underscored_app) { inflector.underscore(app) }
  let(:dir) { underscored_app }
  let(:slice) { "admin" }

  let(:bundled_assets) { true }

  def output
    out.rewind && out.read.chomp
  end

  it "generates slice" do
    within_application_directory do
      subject.call(name: slice)

      # Route
      routes = <<~CODE
        # frozen_string_literal: true

        require "hanami/routes"

        module #{app}
          class Routes < Hanami::Routes
            root { "Hello from Hanami" }

            slice :#{slice}, at: "/#{slice}" do
            end
          end
        end
      CODE

      expect(fs.read("config/routes.rb")).to include(routes)
      expect(output).to include("Created config/routes.rb")

      # Slice directory
      expect(fs.directory?("slices/#{slice}")).to be(true)
      expect(output).to include("Created slices/#{slice}/")

      # # Slice
      # slice_class = <<~CODE
      #   # frozen_string_literal: true
      #
      #   module Admin
      #     class Slice < Hanami::Slice
      #     end
      #   end
      # CODE
      # expect(fs.read("slices/#{slice}/config/slice.rb")).to eq(slice_class)

      # Action
      action = <<~CODE
        # auto_register: false
        # frozen_string_literal: true

        module Admin
          class Action < #{app}::Action
          end
        end
      CODE

      expect(fs.read("slices/#{slice}/action.rb")).to eq(action)
      expect(output).to include("Created slices/#{slice}/action.rb")

      expect(fs.read("slices/#{slice}/actions/.keep")).to eq("")
      expect(output).to include("Created slices/#{slice}/actions/.keep")

      view = <<~RUBY
        # auto_register: false
        # frozen_string_literal: true

        module Admin
          class View < Bookshelf::View
          end
        end
      RUBY
      expect(fs.read("slices/#{slice}/view.rb")).to eq(view)
      expect(output).to include("Created slices/#{slice}/view.rb")

      helpers = <<~RUBY
        # auto_register: false
        # frozen_string_literal: true

        module Admin
          module Views
            module Helpers
              # Add your view helpers here
            end
          end
        end
      RUBY
      expect(fs.read("slices/#{slice}/views/helpers.rb")).to eq(helpers)
      expect(output).to include("Created slices/#{slice}/views/helpers.rb")

      layout = <<~ERB
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>#{inflector.humanize(app)} - #{inflector.humanize(slice)}</title>
            <%= favicon_tag %>
            <%= stylesheet_tag "#{slice}/app" %>
          </head>
          <body>
            <%= yield %>
            <%= javascript_tag "#{slice}/app" %>
          </body>
        </html>
      ERB
      expect(fs.read("slices/#{slice}/templates/layouts/app.html.erb")).to eq(layout)
      expect(output).to include("Created slices/#{slice}/templates/layouts/app.html.erb")

      # slices/admin/assets/js/app.js
      app_js = <<~EXPECTED
        import "../css/app.css";
      EXPECTED
      expect(fs.read("slices/#{slice}/assets/js/app.js")).to eq(app_js)
      expect(output).to include("Created slices/#{slice}/assets/js/app.js")

      # slices/admin/assets/css/app.css
      app_css = <<~EXPECTED
        body {
          background-color: #fff;
          color: #000;
          font-family: sans-serif;
        }
      EXPECTED
      expect(fs.read("slices/#{slice}/assets/css/app.css")).to eq(app_css)
      expect(output).to include("Created slices/#{slice}/assets/css/app.css")
    end
  end

  it "ensures that slice URL prefix is valid" do
    within_application_directory do
      subject.call(name: slice_name = SecureRandom.alphanumeric(16).downcase)
      expected = %(slice :#{slice_name}, at: "/#{slice_name}" do)
      expect(fs.read("config/routes.rb")).to match(expected)

      subject.call(name: slice_name = SecureRandom.alphanumeric(16).downcase, url: "/")
      expected = %(slice :#{slice_name}, at: "/" do)
      expect(fs.read("config/routes.rb")).to match(expected)

      subject.call(name: slice_name = SecureRandom.alphanumeric(16).downcase, url: "/foo_bar")
      expected = %(slice :#{slice_name}, at: "/foo_bar" do)
      expect(fs.read("config/routes.rb")).to match(expected)

      subject.call(name: slice_name = SecureRandom.alphanumeric(16).downcase, url: "/FooBar")
      expected = %(slice :#{slice_name}, at: "/foo_bar" do)
      expect(fs.read("config/routes.rb")).to match(expected)

      expect { subject.call(name: slice, url: " ") }.to raise_error(Hanami::CLI::InvalidURLPrefixError, "invalid URL prefix: ` '")
      expect { subject.call(name: slice, url: "a") }.to raise_error(Hanami::CLI::InvalidURLPrefixError, "invalid URL prefix: `a'")
      expect { subject.call(name: slice, url: "//") }.to raise_error(Hanami::CLI::InvalidURLPrefixError, "invalid URL prefix: `//'")
      expect {
        subject.call(name: slice, url: "//FooBar")
      }.to raise_error(Hanami::CLI::InvalidURLPrefixError, "invalid URL prefix: `//FooBar'")
    end
  end

  it "generates multiple slices over time" do
    within_application_directory do
      subject.call(name: "admin")
      expect(output).to include("Created config/routes.rb")

      subject.call(name: "billing")

      # Route
      routes = <<~CODE
        # frozen_string_literal: true

        require "hanami/routes"

        module #{app}
          class Routes < Hanami::Routes
            root { "Hello from Hanami" }

            slice :admin, at: "/admin" do
            end

            slice :billing, at: "/billing" do
            end
          end
        end
      CODE

      expect(fs.read("config/routes.rb")).to eq(routes)
      expect(output).to include("Updated config/routes.rb")
    end
  end

  context "without hanami-assets" do
    let(:bundled_assets) { false }

    it "generates a slice without hanami-assets" do
      within_application_directory do
        subject.call(name: slice)

        # slices/admin/templates/layouts/app.html.erb
        app_layout = fs.read("slices/#{slice}/templates/layouts/app.html.erb")
        expect(app_layout).to_not match(/favicon/)
        expect(app_layout).to_not match(/css/)
        expect(app_layout).to_not match(/js/)

        # slices/admin/assets/js/app.js
        expect(fs.exist?("slices/admin/assets/js/app.js")).to be(false)

        # slices/admin/app/assets/css/app.css
        expect(fs.exist?("slices/admin/assets/css/app.css")).to be(false)
      end
    end
  end

  private

  def within_application_directory
    application = Struct.new(:namespace).new(app)

    allow(Hanami).to receive(:app).and_return(application)
    allow(Hanami).to receive(:app?).and_return(true)

    fs.mkdir(dir)
    fs.chdir(dir) do
      routes = <<~CODE
        # frozen_string_literal: true

        require "hanami/routes"

        module #{app}
          class Routes < Hanami::Routes
            root { "Hello from Hanami" }
          end
        end
      CODE

      fs.write("config/routes.rb", routes)

      yield
    end
  end
end
