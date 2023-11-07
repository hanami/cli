# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::Gem::New do
  subject do
    described_class.new(bundler: bundler, out: out, fs: fs, inflector: inflector, system_call: system_call)
  end

  let(:bundler) { Hanami::CLI::Bundler.new(fs: fs) }
  let(:out) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:system_call) { instance_double(Hanami::CLI::SystemCall, call: successful_system_call_result) }
  let(:app) { "bookshelf" }
  let(:kwargs) { {head: hanami_head, skip_assets: skip_assets} }

  let(:hanami_head) { false }
  let(:skip_assets) { false }

  let(:output) { out.rewind && out.read.chomp }

  it "normalizes app name" do
    expect(bundler).to receive(:install!)
      .at_least(1)
      .and_return(true)

    expect(bundler).to receive(:exec)
      .with("hanami install")
      .at_least(1)
      .and_return(successful_system_call_result)

    expect(bundler).to receive(:exec)
      .with("check")
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

    expect(bundler).to receive(:exec)
      .with("check")
      .at_least(1)
      .and_return(successful_system_call_result)

    expect(system_call).to receive(:call).with("npm", ["install"])

    subject.call(app: app, **kwargs)

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
        public/
        node_modules/
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

        gem "dry-types", "~> 1.0", ">= 1.6.1"
        gem "puma"
        gem "rake"

        group :development do
          gem "hanami-webconsole", "#{hanami_version}"
        end

        group :development, :test do
          gem "dotenv"
        end

        group :cli, :development do
          gem "hanami-reloader", "#{hanami_version}"
        end

        group :cli, :development, :test do
          gem "hanami-rspec", "#{hanami_version}"
        end
      EXPECTED
      expect(fs.read("Gemfile")).to eq(gemfile)
      expect(output).to include("Created Gemfile")

      # package.json
      hanami_npm_version = Hanami::CLI::Generators::Version.npm_package_requirement
      package_json = <<~EXPECTED
        {
          "name": "#{app}",
          "private": true,
          "scripts": {
            "assets": "node config/assets.mjs"
          },
          "dependencies": {
            "hanami-assets": "#{hanami_npm_version}"
          }
        }
      EXPECTED
      expect(fs.read("package.json")).to eq(package_json)
      expect(output).to include("Created package.json")

      # Procfile.dev
      procfile = <<~EXPECTED
        web: bundle exec hanami server
        assets: bundle exec hanami assets watch
      EXPECTED
      expect(fs.read("Procfile.dev")).to eq(procfile)
      expect(output).to include("Created Procfile.dev")

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

      # bin/dev
      bin_dev = <<~EXPECTED
        #!/usr/bin/env sh

        if ! gem list foreman -i --silent; then
          echo "Installing foreman..."
          gem install foreman
        fi

        exec foreman start -f Procfile.dev "$@"
      EXPECTED
      expect(fs.read("bin/dev")).to eq(bin_dev)
      expect(fs.executable?("bin/dev")).to be(true)
      expect(output).to include("Created bin/dev")

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

      # config/assets.mjs
      assets = <<~EXPECTED
        import * as assets from "hanami-assets";

        await assets.run();

        // To provide additional esbuild (https://esbuild.github.io) options, use the following:
        //
        // await assets.run({
        //   esbuildOptionsFn: (args, esbuildOptions) => {
        //     // Add to esbuildOptions here. Use `args.watch` as a condition for different options for
        //     // compile vs watch.
        //
        //     return esbuildOptions;
        //   }
        // });
      EXPECTED
      expect(fs.read("config/assets.mjs")).to eq(assets)
      expect(output).to include("Created config/assets.mjs")

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
            # Add your routes here. See https://guides.hanamirb.org/routing/overview/ for details.
          end
        end
      EXPECTED
      expect(fs.read("config/routes.rb")).to eq(routes)
      expect(output).to include("Created config/routes.rb")

      # config/puma.rb
      puma = <<~EXPECTED
        # frozen_string_literal: true

        #
        # Environment and port
        #
        port ENV.fetch("HANAMI_PORT", 2300)
        environment ENV.fetch("HANAMI_ENV", "development")

        #
        # Threads within each Puma/Ruby process (aka worker)
        #

        # Configure the minimum and maximum number of threads to use to answer requests.
        max_threads_count = ENV.fetch("HANAMI_MAX_THREADS", 5)
        min_threads_count = ENV.fetch("HANAMI_MIN_THREADS") { max_threads_count }

        threads min_threads_count, max_threads_count

        #
        # Workers (aka Puma/Ruby processes)
        #

        puma_concurrency = Integer(ENV.fetch("HANAMI_WEB_CONCURRENCY", 0))
        puma_cluster_mode = puma_concurrency > 1

        # How many worker (Puma/Ruby) processes to run.
        # Typically this is set to the number of available cores.
        workers puma_concurrency

        #
        # Cluster mode (aka multiple workers)
        #

        if puma_cluster_mode
          # Preload the application before starting the workers. Only in cluster mode.
          preload_app!

          # Code to run immediately before master process forks workers (once on boot).
          #
          # These hooks can block if necessary to wait for background operations unknown
          # to puma to finish before the process terminates. This can be used to close
          # any connections to remote servers (database, redis, …) that were opened when
          # preloading the code.
          before_fork do
            Hanami.shutdown
          end
        end
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

      # app/templates/layouts/app.html.erb
      layout = <<~ERB
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>#{inflector.humanize(app)}</title>
            <%= favicon_tag %>
            <%= stylesheet_tag "app" %>
          </head>
          <body>
            <%= yield %>
            <%= javascript_tag "app" %>
          </body>
        </html>
      ERB
      expect(fs.read("app/templates/layouts/app.html.erb")).to eq(layout)
      expect(output).to include("Created app/templates/layouts/app.html.erb")

      # app/assets/js/app.js
      app_js = <<~EXPECTED
        import "../css/app.css";
      EXPECTED
      expect(fs.read("app/assets/js/app.js")).to eq(app_js)
      expect(output).to include("Created app/assets/js/app.js")

      # app/assets/css/app.css
      app_css = <<~EXPECTED
        body {
          background-color: #fff;
          color: #000;
          font-family: sans-serif;
        }
      EXPECTED
      expect(fs.read("app/assets/css/app.css")).to eq(app_css)
      expect(output).to include("Created app/assets/css/app.css")

      # app/assets/images/favicon.ico
      expect(fs.exist?("app/assets/images/favicon.ico")).to be(true)

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

  context "with head" do
    let(:hanami_head) { true }

    it "generates a new app with Gemfile pointing to hanami HEAD" do
      expect(bundler).to receive(:install!)
        .and_return(true)

      expect(bundler).to receive(:exec)
        .with("hanami install --head")
        .and_return(successful_system_call_result)

      expect(bundler).to receive(:exec)
        .with("check")
        .at_least(1)
        .and_return(successful_system_call_result)

      subject.call(app: app, **kwargs)

      expect(fs.directory?(app)).to be(true)

      fs.chdir(app) do
        # Gemfile
        gemfile = <<~EXPECTED
          # frozen_string_literal: true

          source "https://rubygems.org"

          gem "hanami", github: "hanami/hanami", branch: "main"
          gem "hanami-router", github: "hanami/router", branch: "main"
          gem "hanami-controller", github: "hanami/controller", branch: "main"
          gem "hanami-validations", github: "hanami/validations", branch: "main"
          gem "hanami-view", github: "hanami/view", branch: "main"
          gem "hanami-assets", github: "hanami/assets", branch: "main"

          gem "dry-types", "~> 1.0", ">= 1.6.1"
          gem "puma"
          gem "rake"

          group :development do
            gem "hanami-webconsole", github: "hanami/webconsole", branch: "main"
          end

          group :development, :test do
            gem "dotenv"
          end

          group :cli, :development do
            gem "hanami-reloader", github: "hanami/reloader", branch: "main"
          end

          group :cli, :development, :test do
            gem "hanami-rspec", github: "hanami/rspec", branch: "main"
          end
        EXPECTED
        expect(fs.read("Gemfile")).to eq(gemfile)
        expect(output).to include("Created Gemfile")
      end
    end
  end

  context "without hanami-assets" do
    let(:skip_assets) { true }

    it "generates a new app without hanami-assets" do
      expect(bundler).to receive(:install!)
        .and_return(true)

      expect(bundler).to receive(:exec)
        .with("hanami install")
        .and_return(successful_system_call_result)

      expect(bundler).to receive(:exec)
        .with("check")
        .at_least(1)
        .and_return(successful_system_call_result)

      expect(system_call).not_to receive(:call).with("npm", ["install"])

      subject.call(app: app, **kwargs)

      expect(fs.directory?(app)).to be(true)

      fs.chdir(app) do
        # .gitignore
        gitignore = fs.read(".gitignore")
        expect(gitignore).to_not match(/public/)
        expect(gitignore).to_not match(/node_modules/)

        # Gemfile
        expect(fs.read("Gemfile")).to_not match(/hanami-assets/)

        # package.json
        expect(fs.exist?("package.json")).to be(false)

        # Procfile.dev
        expect(fs.read("Procfile.dev")).to_not match(/hanami assets watch/)

        # config/assets.mjs
        expect(fs.exist?("config/assets.mjs")).to be(false)

        # app/templates/layouts/app.html.erb
        app_layout = fs.read("app/templates/layouts/app.html.erb")
        expect(app_layout).to_not match(/favicon/)
        expect(app_layout).to_not match(/css/)
        expect(app_layout).to_not match(/js/)

        # app/assets/js/app.js
        expect(fs.exist?("app/assets/js/app.js")).to be(false)

        # app/assets/css/app.css
        expect(fs.exist?("app/assets/css/app.css")).to be(false)

        # app/assets/images/favicon.ico
        expect(fs.exist?("app/assets/images/favicon.ico")).to be(false)
      end
    end
  end

  it "respects plural app name" do
    app = "rubygems"

    expect(bundler).to receive(:install!)
      .and_return(true)

    expect(bundler).to receive(:exec)
      .with("hanami install")
      .and_return(successful_system_call_result)

    expect(bundler).to receive(:exec)
      .with("check")
      .at_least(1)
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

  it "calls bundle install if bundle check fails" do
    expect(bundler).to receive(:install!)
      .at_least(1)
      .and_return(true)

    expect(bundler).to receive(:exec)
      .with("hanami install")
      .at_least(1)
      .and_return(successful_system_call_result)

    expect(bundler).to receive(:exec)
      .with("check")
      .at_least(1)
      .and_return(
        instance_double(Hanami::CLI::SystemCall::Result, successful?: false)
      )

    expect(bundler).to receive(:exec)
      .with("install")
      .once
      .and_return(successful_system_call_result)

    app_name = "no_gems_installed"
    subject.call(app: app_name)
  end
end
