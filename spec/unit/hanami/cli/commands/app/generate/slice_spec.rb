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

      expect(fs.read("config/routes.rb")).to include(routes)

      # Slice directory
      expect(fs.directory?("slices/#{slice}")).to be(true)

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

        require "#{underscored_app}/action"

        module Admin
          class Action < #{app}::Action
          end
        end
      CODE

      expect(fs.read("slices/#{slice}/action.rb")).to eq(action)

      expect(fs.read("slices/#{slice}/actions/.keep")).to eq("")
    end
  end

  it "ensures that slice URL prefix is valid" do
    within_application_directory do
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
  end

  it "generates multiple slices over time" do
    within_application_directory do
      subject.call(name: "admin")
      subject.call(name: "billing")

      # Route
      routes = <<~CODE
        # frozen_string_literal: true

        require "hanami/routes"

        module #{app}
          class Routes < Hanami::Routes
            define do
              root { "Hello from Hanami" }

              slice :admin, at: "/admin" do
              end

              slice :billing, at: "/billing" do
              end
            end
          end
        end
      CODE

      expect(fs.read("config/routes.rb")).to eq(routes)
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
