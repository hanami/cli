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

    app_name = "HanamiTeam"
    app = "hanami_team"
    subject.call(app: app_name)

    expect(fs.directory?(app)).to be(true)
  end

  it "generates an app" do
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
        gem "hanami", "#{hanami_version}"

        gem "puma"

        group :cli, :development, :test do
          gem "hanami-rspec"
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

      # config/app.rb
      hanami_app = <<~EXPECTED
        # frozen_string_literal: true

        require "hanami"

        module Bookshelf
          class App < Hanami::App
          end
        end
      EXPECTED
      expect(fs.read("config/app.rb")).to eq(hanami_app)

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
              root { "Hello from Hanami" }
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
