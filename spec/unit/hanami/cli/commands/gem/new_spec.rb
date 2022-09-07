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
  let(:app_path) { "bookshelf" }

  it "creates the app path" do
    expect(bundler).to receive(:install!)
      .at_least(1)
      .and_return(true)

    expect(command_line).to receive(:call)
      .with("hanami install")
      .at_least(1)
      .and_return(successful_system_call_result)

    subject.call(app_path: app_path)

    expect(fs.directory?(app_path)).to be(true)
  end

  it "inflects the app name from the app path's basename" do
    expect(bundler).to receive(:install!)
      .at_least(1)
      .and_return(true)

    expect(command_line).to receive(:call)
      .with("hanami install")
      .at_least(1)
      .and_return(successful_system_call_result)

    subject.call(app_path: app_path)

    expect(fs.read("#{app_path}/config/app.rb")).to include("module Bookshelf")
  end

  it "doesn't fail if the directory already exists", :aggregate_failures do
    expect(bundler).to receive(:install!)
      .at_least(1)
      .and_return(true)

    expect(command_line).to receive(:call)
      .with("hanami install")
      .at_least(1)
      .and_return(successful_system_call_result)

    fs.mkdir(app_path)

    expect { subject.call(app_path: app_path) }.not_to raise_error
    expect(fs.read("#{app_path}/config/app.rb")).to include("module Bookshelf")
  end

  it "can create an app in a nested directory" do
    expect(bundler).to receive(:install!)
      .at_least(1)
      .and_return(true)

    expect(command_line).to receive(:call)
      .with("hanami install")
      .at_least(1)
      .and_return(successful_system_call_result)

    app_path = "code/bookshelf"

    subject.call(app_path: app_path)

    expect(fs.read("#{app_path}/config/app.rb")).to include("module Bookshelf")
  end

  it "generates an app" do
    expect(bundler).to receive(:install!)
      .and_return(true)

    expect(command_line).to receive(:call)
      .with("hanami install")
      .and_return(successful_system_call_result)

    subject.call(app_path: app_path)

    expect(fs.directory?(app_path)).to be(true)

    fs.chdir(app_path) do
      # .env
      env = <<~EXPECTED
      EXPECTED
      expect(fs.read(".env")).to eq(env)

      # README.md
      readme = <<~EXPECTED
        # #{inflector.camelize(app_path)}
      EXPECTED
      expect(fs.read("README.md")).to eq(readme)

      # Gemfile
      hanami_version = Hanami::CLI::Generators::Version.gem_requirement
      gemfile = <<~EXPECTED
        # frozen_string_literal: true

        source "https://rubygems.org"

        gem "hanami", "#{hanami_version}"
        gem "hanami-router", "#{hanami_version}"
        gem "hanami-controller", "#{hanami_version}"
        gem "hanami-validations", "#{hanami_version}"

        gem "dry-types"
        gem "puma"
        gem "rake"

        group :development, :test do
          gem "dotenv"
        end

        group :cli, :development do
          gem "hanami-reloader"
        end

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

        module Bookshelf
          class Settings < Hanami::Settings
            # Define your app settings here, for example:
            #
            # setting :my_flag, default: false, constructor: Types::Params::Bool
          end
        end
      EXPECTED
      expect(fs.read("config/settings.rb")).to eq(settings)

      # config/routes.rb
      routes = <<~EXPECTED
        # frozen_string_literal: true

        module Bookshelf
          class Routes < Hanami::Routes
            define do
              root { "Hello from Hanami" }
            end
          end
        end
      EXPECTED
      expect(fs.read("config/routes.rb")).to eq(routes)

      # config/puma.rb
      puma = <<~EXPECTED
        # frozen_string_literal: true

        max_threads_count = ENV.fetch("HANAMI_MAX_THREADS", 5)
        min_threads_count = ENV.fetch("HANAMI_MIN_THREADS") { max_threads_count }
        threads min_threads_count, max_threads_count

        port        ENV.fetch("HANAMI_PORT", 2300)
        environment ENV.fetch("HANAMI_ENV", "development")
        workers     ENV.fetch("HANAMI_WEB_CONCURRENCY", 2)

        on_worker_boot do
          Hanami.shutdown
        end

        preload_app!
      EXPECTED
      expect(fs.read("config/puma.rb")).to eq(puma)

      # lib/tasks/.keep
      tasks_keep = <<~EXPECTED
      EXPECTED
      expect(fs.read("lib/tasks/.keep")).to eq(tasks_keep)

      # app/action.rb
      action = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "hanami/action"

        module #{inflector.camelize(app_path)}
          class Action < Hanami::Action
          end
        end
      EXPECTED
      expect(fs.read("app/action.rb")).to eq(action)

      # lib/bookshelf/types.rb
      types = <<~EXPECTED
        # frozen_string_literal: true

        require "dry/types"

        module #{inflector.camelize(app_path)}
          Types = Dry.Types

          module Types
            # Define your custom types here
          end
        end
      EXPECTED
      expect(fs.read("lib/#{app_path}/types.rb")).to eq(types)
    end
  end

  it "respects plural app name" do
    app_path = "rubygems"

    expect(bundler).to receive(:install!)
      .and_return(true)

    expect(command_line).to receive(:call)
      .with("hanami install")
      .and_return(successful_system_call_result)

    subject.call(app_path: app_path)

    expect(fs.directory?(app_path)).to be(true)

    fs.chdir(app_path) do
      # README.md
      readme = <<~EXPECTED
        # #{inflector.camelize(app_path)}
      EXPECTED
      expect(fs.read("README.md")).to eq(readme)

      # config/app.rb
      hanami_app = <<~EXPECTED
        # frozen_string_literal: true

        require "hanami"

        module #{inflector.camelize(app_path)}
          class App < Hanami::App
          end
        end
      EXPECTED
      expect(fs.read("config/app.rb")).to eq(hanami_app)
    end
  end
end
