# frozen_string_literal: true

require "hanami/cli/commands/monolith/generate/slice"
require "hanami"
require "ostruct"

RSpec.describe Hanami::CLI::Commands::Monolith::Generate::Slice do
  subject { described_class.new(fs: fs, inflector: inflector, generator: generator) }

  let(:fs) { RSpec::Support::FileSystem.new }
  let(:inflector) { Dry::Inflector.new }
  let(:generator) { Hanami::CLI::Generators::Slice.new(fs: fs, inflector: inflector) }
  let(:app) { "Bookshelf" }
  let(:slice) { "main" }

  it "generates slice" do
    expect(Hanami).to receive(:application)
      .and_return(OpenStruct.new(namespace: app))

    subject.call(slice: slice)

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
end
