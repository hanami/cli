# frozen_string_literal: true

require "hanami/cli/commands/app/generate/slice"
require "securerandom"

RSpec.describe Hanami::CLI::Commands::App::Generate::Slice do
  subject { described_class.new(fs: fs, inflector: inflector, generator: generator) }

  let(:fs) { Dry::Files.new(memory: true) }
  let(:inflector) { Dry::Inflector.new }
  let(:generator) { Hanami::CLI::Generators::App::Slice.new(fs: fs, inflector: inflector) }
  let(:app) { "Bookshelf" }
  let(:slice) { "main" }

  it "generates slice" do
    pending "FIXME: something changed and the output has too many new-lines now"

    expect(Hanami).to receive(:app)
      .and_return(successful_system_call_result)

    routes_contents = <<~CODE
      # frozen_string_literal: true

      Hanami.app.routes do
      end
    CODE
    fs.write("config/routes.rb", routes_contents)

    subject.call(name: slice, url_prefix: "/")

    # config/routes.rb
    routes = <<~EXPECTED
      # frozen_string_literal: true

      Hanami.app.routes do
        slice :main, at: "/" do
        end
      end
    EXPECTED
    expect(fs.read("config/routes.rb")).to eq(routes)

    expect(fs.directory?(directory = "slices/#{slice}")).to be(true)

    fs.chdir(directory) do
      # action.rb
      action = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "#{inflector.underscore(app)}/action"

        module #{inflector.classify(slice)}
          class Action < #{inflector.classify(app)}::Action
          end
        end
      EXPECTED
      expect(fs.read("action.rb")).to eq(action)

      # view.rb
      view = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "#{inflector.underscore(app)}/view"

        module #{inflector.classify(slice)}
          class View < #{inflector.classify(app)}::View
          end
        end
      EXPECTED
      expect(fs.read("view.rb")).to eq(view)

      # entities.rb
      entities = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        module #{inflector.classify(slice)}
          module Entities
          end
        end

        Dir[File.join(__dir__, "entities", "*.rb")].each(&method(:require))
      EXPECTED
      expect(fs.read("entities.rb")).to eq(entities)

      # repository.rb
      repository = <<~EXPECTED
        # frozen_string_literal: true

        require "#{inflector.underscore(app)}/repository"
        require_relative "entities"

        module #{inflector.classify(slice)}
          class Repository < #{inflector.classify(app)}::Repository
            struct_namespace Entities
          end
        end
      EXPECTED
      expect(fs.read("repository.rb")).to eq(repository)

      # actions/.keep
      actions_keep = <<~EXPECTED
      EXPECTED
      expect(fs.read("actions/.keep")).to eq(actions_keep)

      # views/.keep
      views_keep = <<~EXPECTED
      EXPECTED
      expect(fs.read("views/.keep")).to eq(views_keep)

      # templates/.keep
      templates_keep = <<~EXPECTED
      EXPECTED
      expect(fs.read("templates/.keep")).to eq(templates_keep)

      # templates/.keep
      templates_layouts_keep = <<~EXPECTED
      EXPECTED
      expect(fs.read("templates/layouts/.keep")).to eq(templates_layouts_keep)

      # entities/.keep
      entities_keep = <<~EXPECTED
      EXPECTED
      expect(fs.read("entities/.keep")).to eq(entities_keep)

      # repository/.keep
      repositories_keep = <<~EXPECTED
      EXPECTED
      expect(fs.read("repositories/.keep")).to eq(repositories_keep)
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

  it "ensures that slice URL prefix is valid" do
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
end
