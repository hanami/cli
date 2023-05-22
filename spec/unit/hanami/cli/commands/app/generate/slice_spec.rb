require "hanami"
require "securerandom"

RSpec.describe Hanami::CLI::Commands::App::Generate::Slice do
  subject { described_class.new(fs: fs, inflector: inflector, generator: generator) }

  let(:out) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:generator) { Hanami::CLI::Generators::App::Slice.new(fs: fs, inflector: inflector) }
  let(:app) { "Bookshelf" }
  let(:underscored_app) { inflector.underscore(app) }
  let(:dir) { underscored_app }
  let(:slice) { "admin" }

  def output
    out.rewind && out.read.chomp
  end

  it "generates slice" do
    within_application_directory do
      subject.call(name: slice)

      # Route
      routes = <<~CODE
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
        module Admin
          class Action < #{app}::Action
          end
        end
      CODE

      expect(fs.read("slices/#{slice}/action.rb")).to eq(action)
      expect(output).to include("Created slices/#{slice}/action.rb")

      expect(fs.read("slices/#{slice}/actions/.keep")).to eq("")
      expect(output).to include("Created slices/#{slice}/actions/.keep")
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

  private

  def within_application_directory
    application = Struct.new(:namespace).new(app)

    allow(Hanami).to receive(:app).and_return(application)
    allow(Hanami).to receive(:app?).and_return(true)

    fs.mkdir(dir)
    fs.chdir(dir) do
      routes = <<~CODE
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
