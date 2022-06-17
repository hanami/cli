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
      hanami_version = Hanami::CLI::Generators::Version.gem_requirement
      gemfile = <<~EXPECTED
        # frozen_string_literal: true

        source "https://rubygems.org"

        gem "rake"

        gem "hanami-router", "#{hanami_version}"
        gem "hanami-controller", "#{hanami_version}"
        gem "hanami-validations", "#{hanami_version}"
        gem "hanami-view", git: "https://github.com/hanami/view.git", branch: "main"
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

        require "hanami/rake_tasks"
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
        require "hanami/settings"

        module Bookshelf
          class Settings < Hanami::Settings
          end
        end
      EXPECTED
      expect(fs.read("config/settings.rb")).to eq(settings)

      # config/routes.rb
      routes = <<~EXPECTED
        # frozen_string_literal: true

        require "hanami/routes"

        module Bookshelf
          class Routes < Hanami::Routes
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

      # app/view.rb
      view = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "hanami/view"

        module #{inflector.classify(app)}
          class View < Hanami::View
          end
        end
      EXPECTED
      expect(fs.read("app/view.rb")).to eq(view)

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

      # app/views/part.rb
      view_part = <<~EXPECTED
        # frozen_string_literal: true

        require "hanami/view/part"

        module #{inflector.classify(app)}
          module Views
            class Part < Hanami::View::Part
            end
          end
        end
      EXPECTED
      expect(fs.read("app/views/part.rb")).to eq(view_part)

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
