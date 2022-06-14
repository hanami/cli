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

        require "bookshelf/types"
        require "hanami/application/settings"

        module Bookshelf
          class Settings < Hanami::Application::Settings
            # Database
            setting :database do
              setting :default do
                setting :url, constructor: Types::String
              end
            end
          end
        end
      EXPECTED
      expect(fs.read("config/settings.rb")).to eq(settings)

      # config/routes.rb
      routes = <<~EXPECTED
        # frozen_string_literal: true

        require "hanami/application/routes"

        module Bookshelf
          class Routes < Hanami::Application::Routes
            define do
            end
          end
        end
      EXPECTED
      expect(fs.read("config/routes.rb")).to eq(routes)

      # lib/tasks/.keep
      tasks_keep = <<~EXPECTED
      EXPECTED
      expect(fs.read("lib/tasks/.keep")).to eq(tasks_keep)

      # app/entities/.keep
      entities_keep = <<~EXPECTED
      EXPECTED
      expect(fs.read("app/entities/.keep")).to eq(entities_keep)

      # app/relations/.keep
      relations_keep = <<~EXPECTED
      EXPECTED
      expect(fs.read("app/relations/.keep")).to eq(relations_keep)

      # app/repositories/.keep
      repositories_keep = <<~EXPECTED
      EXPECTED
      expect(fs.read("app/repositories/.keep")).to eq(repositories_keep)

      # lib/bookshelf/validator.rb
      validator = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "dry/validation"
        require "dry/schema/messages/i18n"

        module #{inflector.classify(app)}
          module Validator < Dry::Validation::Contract
            config.messages.backend = :i18n
            config.messages.top_namespace = "validation"
          end
        end
      EXPECTED
      expect(fs.read("lib/#{app}/validator.rb")).to eq(validator)

      # app/views/context.rb
      view_context = <<~EXPECTED
        # frozen_string_literal: true

        require "hanami/view/context"

        module #{inflector.classify(app)}
          module Views
            class Context < Hanami::View::Context
            end
          end
        end
      EXPECTED
      expect(fs.read("app/views/context.rb")).to eq(view_context)

      # app/action.rb
      action = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "hanami/action"

        module #{inflector.classify(app)}
          class Action < Hanami::Action
          end
        end
      EXPECTED
      expect(fs.read("app/action.rb")).to eq(action)

      # lib/bookshelf/transformations.rb
      functions = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "dry/transformer"

        module #{inflector.classify(app)}
          module Transformations
            extend Dry::Transformer::Registry

            import Dry::Transformer::ArrayTransformations
            import Dry::Transformer::HashTransformations
          end
        end
      EXPECTED
      expect(fs.read("lib/#{app}/transformations.rb")).to eq(functions)

      # lib/bookshelf/operation.rb
      operation = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "hanami/operation"

        module #{inflector.classify(app)}
          class Operation < Hanami::Operation
          end
        end
      EXPECTED
      expect(fs.read("lib/#{app}/operation.rb")).to eq(operation)

      # app/repository.rb
      repository = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "hanami/repository"

        module #{inflector.classify(app)}
          class Repository < Hanami::Repository
          end
        end
      EXPECTED
      expect(fs.read("app/repository.rb")).to eq(repository)

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
