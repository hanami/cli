# frozen_string_literal: true

require "hanami/cli/commands/monolith/generate/action"
require "hanami"
require "ostruct"

RSpec.describe Hanami::CLI::Commands::Monolith::Generate::Action do
  subject { described_class.new(fs: fs, inflector: inflector, generator: generator) }

  let(:fs) { Dry::CLI::Utils::Files.new(memory: true) }
  let(:inflector) { Dry::Inflector.new }
  let(:generator) { Hanami::CLI::Generators::Monolith::Action.new(fs: fs, inflector: inflector) }
  let(:app) { "Bookshelf" }
  let(:slice) { "main" }
  let(:controller) { "users" }
  let(:action) { "show" }
  let(:action_name) { "#{controller}.#{action}" }

  it "generates action" do
    fs.mkdir("slices/#{slice}")

    subject.call(slice: slice, name: action_name)

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
      fs.mkdir("slices/#{slice}")

      subject.call(slice: slice, name: action_name)

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

  it "raises error if slice is unexisting" do
    expect { subject.call(slice: slice, name: action_name) }.to raise_error(ArgumentError, "slice not found `#{slice}'")
  end

  it "raises error if action name doesn't respect the convention" do
    fs.mkdir("slices/#{slice}")
    expect {
      subject.call(slice: slice,
                   name: "foo")
    }.to raise_error(ArgumentError, "cannot parse controller and action name: `foo'\n\texample: users.show")
  end

  it "allows to specify MIME Type for template" do
    fs.mkdir("slices/#{slice}")

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

  xit "can skip view creation"
end
