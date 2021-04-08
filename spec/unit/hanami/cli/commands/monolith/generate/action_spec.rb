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

  xit "raises error if slice is unexisting"
  xit "raises error if action name doesn't respect the convention"
  xit "creates deeply nested action" do
    # assert template <h1> and <h2>
  end
  xit "can skip view creation"
  xit "allows to specify MIME Type for template"
end
