# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::Gem::New do
  subject {
    described_class.new(bundler: bundler, out: out, fs: fs, inflector: inflector)
  }

  let(:bundler) { Hanami::CLI::Bundler.new(fs: fs) }
  let(:out) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { "bookshelf" }

  let(:output) { out.rewind && out.read.chomp }

  it "normalizes app name" do
    expect(bundler).to receive(:install!)
      .at_least(1)
      .and_return(true)

    expect(bundler).to receive(:exec)
      .with("hanami install")
      .at_least(1)
      .and_return(successful_system_call_result)

    app_name = "HanamiTeam"
    app = "hanami_team"
    subject.call(app: app_name)

    expect(fs.directory?(app)).to be(true)

    app_name = "Rubygems"
    app = "rubygems"
    subject.call(app: app_name)

    expect(fs.directory?(app)).to be(true)

    app_name = "CodeInsights"
    app = "code_insights"
    subject.call(app: app_name)

    expect(fs.directory?(app)).to be(true)
  end

  it "generates an app" do
    expect(bundler).to receive(:install!)
      .and_return(true)

    expect(bundler).to receive(:exec)
      .with("hanami install")
      .and_return(successful_system_call_result)

    subject.call(app: app)

    expect(fs.directory?(app)).to be(true)
    expect(output).to include("Created #{app}/")
    expect(output).to include("-> Within #{app}/")
    expect(output).to include("Running Bundler install...")
    expect(output).to include("Running Hanami install...")

    fs.chdir(app) do
      # .gitignore
      gitignore = <<~EXPECTED
        .env
        log/*
      EXPECTED
      expect(fs.read(".gitignore")).to eq(gitignore)
      expect(output).to include("Created .gitignore")

      # .env
      env = <<~EXPECTED
      EXPECTED
      expect(fs.read(".env")).to eq(env)
      expect(output).to include("Created .env")

      # README.md
      readme = <<~EXPECTED
        # #{inflector.camelize(app)}
      EXPECTED
      expect(fs.read("README.md")).to eq(readme)
      expect(output).to include("Created README.md")

      # Gemfile
      hanami_version = Hanami::CLI::Generators::Version.gem_requirement
      gemfile = <<~EXPECTED
        # frozen_string_literal: true

        source "https://rubygems.org"

        gem "hanami", "#{hanami_version}"
        gem "hanami-router", "#{hanami_version}"
        gem "hanami-controller", "#{hanami_version}"
        gem "hanami-validations", "#{hanami_version}"
        gem "hanami-view", "#{hanami_version}"
        gem "hanami-assets", "#{hanami_version}"
        gem "hanami-webconsole", "#{hanami_version}"

        gem "dry-types", "~> 1.0", ">= 1.6.1"
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
      expect(output).to include("Created Gemfile")

      # Rakefile
      rakefile = <<~EXPECTED
        # frozen_string_literal: true

        require "hanami/rake_tasks"
      EXPECTED
      expect(fs.read("Rakefile")).to eq(rakefile)
      expect(output).to include("Created Rakefile")

      # config.ru
      config_ru = <<~EXPECTED
        # frozen_string_literal: true

        require "hanami/boot"

        run Hanami.app
      EXPECTED
      expect(fs.read("config.ru")).to eq(config_ru)
      expect(output).to include("Created config.ru")

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
      expect(output).to include("Created config/app.rb")

      # config/settings.rb
      settings = <<~EXPECTED
        # frozen_string_literal: true

        module Bookshelf
          class Settings < Hanami::Settings
            # Define your app settings here, for example:
            #
            # setting :my_flag, default: false, constructor: Types::Params::Bool
          end
        end
      EXPECTED
      expect(fs.read("config/settings.rb")).to eq(settings)
      expect(output).to include("Created config/settings.rb")

      # config/routes.rb
      routes = <<~EXPECTED
        # frozen_string_literal: true

        module Bookshelf
          class Routes < Hanami::Routes
            root { "Hello from Hanami" }
          end
        end
      EXPECTED
      expect(fs.read("config/routes.rb")).to eq(routes)
      expect(output).to include("Created config/routes.rb")

      # config/puma.rb
      puma = <<~EXPECTED
        # frozen_string_literal: true

        max_threads_count = ENV.fetch("HANAMI_MAX_THREADS", 5)
        min_threads_count = ENV.fetch("HANAMI_MIN_THREADS") { max_threads_count }
        threads min_threads_count, max_threads_count

        port        ENV.fetch("HANAMI_PORT", 2300)
        environment ENV.fetch("HANAMI_ENV", "development")
        workers     ENV.fetch("HANAMI_WEB_CONCURRENCY", 0)

        if ENV.fetch("HANAMI_WEB_CONCURRENCY", 0) > 0
          on_worker_boot do
            Hanami.shutdown
          end
        end

        preload_app!
      EXPECTED
      expect(fs.read("config/puma.rb")).to eq(puma)
      expect(output).to include("Created config/puma.rb")

      # lib/tasks/.keep
      tasks_keep = <<~EXPECTED
      EXPECTED
      expect(fs.read("lib/tasks/.keep")).to eq(tasks_keep)
      expect(output).to include("Created lib/tasks/.keep")

      # app/action.rb
      action = <<~EXPECTED
        # auto_register: false
        # frozen_string_literal: true

        require "hanami/action"

        module #{inflector.camelize(app)}
          class Action < Hanami::Action
          end
        end
      EXPECTED
      expect(fs.read("app/action.rb")).to eq(action)
      expect(output).to include("Created app/action.rb")

      # app/view.rb
      view = <<~RUBY
        # auto_register: false
        # frozen_string_literal: true

        require "hanami/view"

        module #{inflector.camelize(app)}
          class View < Hanami::View
          end
        end
      RUBY
      expect(fs.read("app/view.rb")).to eq(view)
      expect(output).to include("Created app/view.rb")

      # app/views/helpers.rb
      helpers = <<~RUBY
        # auto_register: false
        # frozen_string_literal: true

        module #{inflector.camelize(app)}
          module Views
            module Helpers
              # Add your view helpers here
            end
          end
        end
      RUBY
      expect(fs.read("app/views/helpers.rb")).to eq(helpers)
      expect(output).to include("Created app/views/helpers.rb")

      # templates/layouts/app.html.erb
      layout = <<~ERB
        <%= yield %>
      ERB
      expect(fs.read("app/templates/layouts/app.html.erb")).to eq(layout)
      expect(output).to include("Created app/templates/layouts/app.html.erb")

      # lib/bookshelf/types.rb
      types = <<~EXPECTED
        # frozen_string_literal: true

        require "dry/types"

        module #{inflector.camelize(app)}
          Types = Dry.Types

          module Types
            # Define your custom types here
          end
        end
      EXPECTED
      expect(fs.read("lib/#{app}/types.rb")).to eq(types)
      expect(output).to include("Created lib/bookshelf/types.rb")

      # public/ error pages
      expect(fs.read("public/404.html")).to include %(<title>The page you were looking for doesn’t exist (404)</title>)
      expect(fs.read("public/500.html")).to include %(<title>We’re sorry, but something went wrong (500)</title>)
    end
  end

  it "respects plural app name" do
    app = "rubygems"

    expect(bundler).to receive(:install!)
      .and_return(true)

    expect(bundler).to receive(:exec)
      .with("hanami install")
      .and_return(successful_system_call_result)

    subject.call(app: app)

    expect(fs.directory?(app)).to be(true)

    fs.chdir(app) do
      # README.md
      readme = <<~EXPECTED
        # #{inflector.camelize(app)}
      EXPECTED
      expect(fs.read("README.md")).to eq(readme)

      # config/app.rb
      hanami_app = <<~EXPECTED
        # frozen_string_literal: true

        require "hanami"

        module #{inflector.camelize(app)}
          class App < Hanami::App
          end
        end
      EXPECTED
      expect(fs.read("config/app.rb")).to eq(hanami_app)
    end
  end

  it "doesn't create app in existing folder" do
    fs.mkdir("bookshelf")

    expect(bundler).to_not receive(:install!)
    expect(bundler).to_not receive(:exec)

    expect { subject.call(app: app) }.to raise_error(Hanami::CLI::PathAlreadyExistsError)
  end
end
