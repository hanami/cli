# frozen_string_literal: true

require "hanami/cli/commands/gem/new"

RSpec.describe Hanami::CLI::Commands::Gem::New do
  subject {
    described_class.new(bundler: bundler, command_line: command_line, out: stdout, fs: fs, inflector: inflector)
  }

  let(:bundler) { Hanami::CLI::Bundler.new(fs: fs) }
  let(:command_line) { Hanami::CLI::CommandLine.new(bundler: bundler) }
  let(:stdout) { StringIO.new }
  let(:fs) { Dry::Files.new(memory: true) }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { "bookshelf" }

  it "normalizes app name" do
    expect(bundler).to receive(:install!)
      .and_return(true)

    expect(command_line).to receive(:call)
      .with("hanami install")
      .and_return(successful_system_call_result)

    app_name = "PropagandaLive"
    app = "propaganda_live"
    subject.call(app: app_name)

    expect(fs.directory?(app)).to be(true)
  end

  it "generates an application" do
    expect(bundler).to receive(:install!)
      .and_return(true)

    expect(command_line).to receive(:call)
      .with("hanami install")
      .and_return(successful_system_call_result)

    subject.call(app: app)

    expect(fs.directory?(app)).to be(true)

    fs.chdir(app) do
      # .env
      env = <<~EXPECTED
      EXPECTED
      expect(fs.read(".env")).to eq(env)

      # README.md
      readme = <<~EXPECTED
        # #{inflector.classify(app)}
      EXPECTED
      expect(fs.read("README.md")).to eq(readme)

      # Gemfile
      hanami_version = Hanami::Version.gem_requirement
      gemfile = <<~EXPECTED
        # frozen_string_literal: true

        source "https://rubygems.org"

        gem "rake"

        gem "hanami-router", "#{hanami_version}"
        gem "hanami-controller", "#{hanami_version}"
        gem "hanami-validations", "#{hanami_version}"
        gem "hanami-view", git: "https://github.com/hanami/view.git", branch: "master"
        gem "dry-cli", "~> 0.6", require: false, git: "https://github.com/dry-rb/dry-cli.git", branch: "feature/file-utils-class"
        gem "hanami-cli", git: "https://github.com/hanami/cli.git", branch: "main"
        gem "hanami", require: false, git: "https://github.com/hanami/hanami.git", branch: "feature/hanami-2-cli"

        gem "puma"

        group :cli, :development, :test do
          gem "hanami-rspec", git: "https://github.com/hanami/rspec.git", branch: "main"
        end
      EXPECTED
      expect(fs.read("Gemfile")).to eq(gemfile)

      # Rakefile
      rakefile = <<~EXPECTED
        # frozen_string_literal: true

        require "hanami/application/rake_tasks"
      EXPECTED
      expect(fs.read("Rakefile")).to eq(rakefile)

      # config.ru
      config_ru = <<~EXPECTED
        # frozen_string_literal: true

        require "hanami/boot"

        run Hanami.app
      EXPECTED
      expect(fs.read("config.ru")).to eq(config_ru)

      # config/application.rb
      application = <<~EXPECTED
        # frozen_string_literal: true

        require "hanami"

        module Bookshelf
          class Application < Hanami::Application
          end
        end
      EXPECTED
      expect(fs.read("config/application.rb")).to eq(application)

      # config/settings.rb
      settings = <<~EXPECTED
        # frozen_string_literal: true

        require "#{app}/types"

        Hanami.application.settings do
        end
      EXPECTED
      expect(fs.read("config/settings.rb")).to eq(settings)

      # config/routes.rb
      routes = <<~EXPECTED
        # frozen_string_literal: true

        Hanami.application.routes do
        end
      EXPECTED
      expect(fs.read("config/routes.rb")).to eq(routes)

      # lib/tasks/.keep
      tasks_keep = <<~EXPECTED
      EXPECTED
      expect(fs.read("lib/tasks/.keep")).to eq(tasks_keep)

      # lib/bookshelf/entities/.keep
      entities_keep = <<~EXPECTED
      EXPECTED
      expect(fs.read("lib/#{app}/entities/.keep")).to eq(entities_keep)

      # lib/bookshelf/persistence/relations/.keep
      persistence_relations_keep = <<~EXPECTED
      EXPECTED
      expect(fs.read("lib/#{app}/persistence/relations/.keep")).to eq(persistence_relations_keep)

      # lib/bookshelf/persistence/relations/.keep
      persistence_relations_keep = <<~EXPECTED
      EXPECTED
      expect(fs.read("lib/#{app}/persistence/relations/.keep")).to eq(persistence_relations_keep)

      # lib/bookshelf/validation/contract.rb
      validation_contract = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "dry/validation"
        require "dry/schema/messages/i18n"

        module #{inflector.classify(app)}
          module Validation
            class Contract < Dry::Validation::Contract
              config.messages.backend = :i18n
              config.messages.top_namespace = "validation"
            end
          end
        end
      EXPECTED
      expect(fs.read("lib/#{app}/validation/contract.rb")).to eq(validation_contract)

      # lib/bookshelf/view/context.rb
      view_context = <<~EXPECTED
        # frozen_string_literal: true

        require "hanami/view/context"

        module #{inflector.classify(app)}
          module View
            class Context < Hanami::View::Context
              def initialize(**args)
                defaults = {content: {}}

                super(**defaults.merge(args))
              end
            end
          end
        end
      EXPECTED
      expect(fs.read("lib/#{app}/view/context.rb")).to eq(view_context)

      # lib/bookshelf/action.rb
      action = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "json" # required for Hanami::Action::Flash to work
        require "hanami/action"
        require "hanami/action/cookies"
        require "hanami/action/csrf_protection"
        require "hanami/action/session"

        module #{inflector.classify(app)}
          class Action < Hanami::Action
            def self.inherited(klass)
              super

              # These will need to be sorted by the framework eventually
              klass.include Hanami::Action::Cookies
              klass.include Hanami::Action::Session
              klass.include Hanami::Action::CSRFProtection
            end
          end
        end
      EXPECTED
      expect(fs.read("lib/#{app}/action.rb")).to eq(action)

      # lib/bookshelf/entities.rb
      entities = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        module #{inflector.classify(app)}
          module Entities
          end
        end

        Dir[File.join(__dir__, "entities", "*.rb")].each(&method(:require))
      EXPECTED
      expect(fs.read("lib/#{app}/entities.rb")).to eq(entities)

      # lib/bookshelf/functions.rb
      functions = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "dry/transformer"

        module #{inflector.classify(app)}
          module Functions
            extend Dry::Transformer::Registry

            import Dry::Transformer::ArrayTransformations
            import Dry::Transformer::HashTransformations
          end
        end
      EXPECTED
      expect(fs.read("lib/#{app}/functions.rb")).to eq(functions)

      # lib/bookshelf/operation.rb
      operation = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "dry/monads"
        require "dry/matcher/result_matcher"

        module #{inflector.classify(app)}
          class Operation
            include Dry::Monads[:result, :try]

            class << self
              def inherited(klass)
                klass.include Dry::Monads[:do]
                klass.include Dry::Matcher::ResultMatcher.for(:call)
              end
            end
          end
        end
      EXPECTED
      expect(fs.read("lib/#{app}/operation.rb")).to eq(operation)

      # lib/bookshelf/repository.rb
      repository = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "rom-repository"
        require_relative "entities"

        module #{inflector.classify(app)}
          class Repository < ROM::Repository::Root
            include Deps[container: "persistence.rom"]

            struct_namespace Entities
          end
        end
      EXPECTED
      expect(fs.read("lib/#{app}/repository.rb")).to eq(repository)

      # lib/bookshelf/types.rb
      types = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "dry/types"

        module #{inflector.classify(app)}
          module Types
            include Dry.Types
          end
        end
      EXPECTED
      expect(fs.read("lib/#{app}/types.rb")).to eq(types)
    end
  end
end
