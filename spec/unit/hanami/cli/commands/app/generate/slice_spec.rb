# frozen_string_literal: true

require "hanami"
require "hanami/cli/commands/app/generate/slice"
require "securerandom"

RSpec.describe Hanami::CLI::Commands::App::Generate::Slice do
  subject { described_class.new(fs: fs, inflector: inflector, generator: generator) }

  let(:fs) { Dry::Files.new(memory: true) }
  let(:inflector) { Dry::Inflector.new }
  let(:generator) { Hanami::CLI::Generators::App::Slice.new(fs: fs, inflector: inflector) }
  let(:app) { "Bookshelf" }
  let(:underscored_app) { inflector.underscore(app) }
  let(:dir) { underscored_app }
  let(:slice) { "admin" }

  it "generates slice" do
    within_application_directory do
      subject.call(name: slice)

      # Route
      route = <<~CODE
        slice :#{slice}, at: "/#{slice}" do
      CODE

      expect(fs.read("config/routes.rb")).to include(route)

      # Directory
      expect(fs.directory?("slices/#{slice}")).to be(true)

      # Action
      action = <<~CODE
        # auto_register: false
        # frozen_string_literal: true

        require "#{underscored_app}/action"

        module Admin
          class Action < #{app}::Action
          end
        end
      CODE

      expect(fs.read("slices/#{slice}/action.rb")).to eq(action)
    end
  end

  it "uses slice name as URL prefix default" do
    pending "FIXME: something changed and the output has too many new-lines now"

    app = Struct.new(:namespace).new(app)

    expect(Hanami).to receive(:app)
      .and_return(app)

    routes_contents = <<~CODE
      # frozen_string_literal: true

      Hanami.app.routes do
      end
    CODE
    fs.write("config/routes.rb", routes_contents)

    subject.call(name: "FooBar")

    # config/routes.rb
    routes = <<~EXPECTED
      # frozen_string_literal: true

      Hanami.app.routes do
        slice :foo_bar, at: "/foo_bar" do
        end
      end
    EXPECTED
    expect(fs.read("config/routes.rb")).to eq(routes)
  end

  xit "ensures that slice URL prefix is valid" do
    app = Struct.new(:namespace).new(app)

    expect(Hanami).to receive(:app)
      .and_return(app)
      .at_least(:once)

    routes_contents = <<~CODE
      # frozen_string_literal: true

      Hanami.app.routes do
      end
    CODE
    fs.write("config/routes.rb", routes_contents)

    subject.call(name: slice_name = SecureRandom.alphanumeric(16).downcase)
    expected = %(slice :#{slice_name}, at: "/#{slice_name}" do)
    expect(fs.read("config/routes.rb")).to match(expected)

    subject.call(name: slice_name = SecureRandom.alphanumeric(16).downcase, url_prefix: "/")
    expected = %(slice :#{slice_name}, at: "/" do)
    expect(fs.read("config/routes.rb")).to match(expected)

    subject.call(name: slice_name = SecureRandom.alphanumeric(16).downcase, url_prefix: "/foo_bar")
    expected = %(slice :#{slice_name}, at: "/foo_bar" do)
    expect(fs.read("config/routes.rb")).to match(expected)

    subject.call(name: slice_name = SecureRandom.alphanumeric(16).downcase, url_prefix: "/FooBar")
    expected = %(slice :#{slice_name}, at: "/foo_bar" do)
    expect(fs.read("config/routes.rb")).to match(expected)

    expect { subject.call(name: slice, url_prefix: " ") }.to raise_error(ArgumentError, "invalid URL prefix: ` '")
    expect { subject.call(name: slice, url_prefix: "a") }.to raise_error(ArgumentError, "invalid URL prefix: `a'")
    expect { subject.call(name: slice, url_prefix: "//") }.to raise_error(ArgumentError, "invalid URL prefix: `//'")
    expect {
      subject.call(name: slice, url_prefix: "//FooBar")
    }.to raise_error(ArgumentError, "invalid URL prefix: `//FooBar'")
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
end
