# frozen_string_literal: true

require "hanami"
require "ostruct"

RSpec.describe Hanami::CLI::Commands::App::Generate::View, :app do
  subject { described_class.new(fs: fs, inflector: inflector, generator: generator) }

  let(:out) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:generator) { Hanami::CLI::Generators::App::View.new(fs: fs, inflector: inflector) }
  let(:app) { Hanami.app.namespace }
  let(:dir) { inflector.underscore(app) }

  def output
    out.rewind && out.read.chomp
  end

  # it "raises error if action name doesn't respect the convention" do
  #   expect {
  #     subject.call(name: "foo")
  #   }.to raise_error(Hanami::CLI::InvalidActionNameError, "cannot parse controller and action name: `foo'\n\texample: `hanami generate action users.show'")
  # end

  context "generating for app" do
    it "generates a view in a top-level namespace" do
      within_application_directory do
        subject.call(name: "users.index")

        # view
        view_file = <<~EXPECTED
          # frozen_string_literal: true

          module Test
            module Views
              module Users
                class Index < Test::View
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("app/views/users/index.rb")).to eq(view_file)
        expect(output).to include("Created app/views/users/index.rb")

        # template
        expect(fs.directory?("app/templates/users")).to be(true)

        template_file = <<~EXPECTED
          <h1>Test::Views::Users::Index</h1>
        EXPECTED

        expect(fs.read("app/templates/users/index.html.erb")).to eq(template_file)
        expect(output).to include("Created app/views/users/index.rb")
      end
    end

    it "generates a view in a deeper namespace" do
      within_application_directory do
        subject.call(name: "special.users.index")

        # view
        view_file = <<~EXPECTED
          # frozen_string_literal: true

          module Test
            module Views
              module Special
                module Users
                  class Index < Test::View
                  end
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("app/views/special/users/index.rb")).to eq(view_file)
        expect(output).to include("Created app/views/special/users/index.rb")

        # template
        expect(fs.directory?("app/templates/special/users")).to be(true)

        template_file = <<~EXPECTED
          <h1>Test::Views::Special::Users::Index</h1>
        EXPECTED

        expect(fs.read("app/templates/special/users/index.html.erb")).to eq(template_file)
        expect(output).to include("Created app/views/special/users/index.rb")
      end
    end
  end

  context "generating for a slice" do
    it "generates a view in a top-level namespace" do
      within_application_directory do
        fs.mkdir("slices/main")
        subject.call(name: "users.index", slice: "main")

        # view
        view_file = <<~EXPECTED
          # frozen_string_literal: true

          module Main
            module Views
              module Users
                class Index < Main::View
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("slices/main/views/users/index.rb")).to eq(view_file)
        expect(output).to include("Created slices/main/views/users/index.rb")

        # template
        expect(fs.directory?("slices/main/templates/users")).to be(true)

        template_file = <<~EXPECTED
          <h1>Main::Views::Users::Index</h1>
        EXPECTED

        expect(fs.read("slices/main/templates/users/index.html.erb")).to eq(template_file)
        expect(output).to include("Created slices/main/views/users/index.rb")
      end
    end
  end

  private

  def within_application_directory
    fs.mkdir(dir)
    fs.chdir(dir) do
      routes = <<~CODE
        # frozen_string_literal: true

        require "hanami/routes"

        module #{app}
          class Routes < Hanami::Routes
            root { "Hello from Hanami" }
          end
        end
      CODE

      fs.write("config/routes.rb", routes)

      yield
    end
  end
end
