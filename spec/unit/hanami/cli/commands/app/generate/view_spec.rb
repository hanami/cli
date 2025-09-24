# frozen_string_literal: true

require "hanami"
require "ostruct"

RSpec.describe Hanami::CLI::Commands::App::Generate::View, :app do
  subject { described_class.new(fs: fs, out: out, err: err) }

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { Hanami.app.namespace }
  let(:dir) { inflector.underscore(app) }

  def output
    out.rewind && out.read.chomp
  end

  def error_output = err.string.chomp

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
        expect(output).to include("Created app/templates/users/index.html.erb")
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
        expect(output).to include("Created app/templates/special/users/index.html.erb")
      end
    end

    context "with existing view file" do
      let(:file_path) { "app/views/users/index.rb" }

      before do
        within_application_directory do
          fs.write(file_path, "existing content")
        end
      end

      it "exits with error message" do
        expect do
          within_application_directory { subject.call(name: "users.index") }
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
      end
    end

    context "with existing template file" do
      let(:file_path) { "app/templates/users/index.html.erb" }

      before do
        within_application_directory do
          fs.write(file_path, "existing content")
        end
      end

      it "raises error" do
        within_application_directory do
          expect do
            subject.call(name: "users.index")
          end.to raise_error SystemExit do |exception|
            expect(exception.status).to eq 1
            expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
          end
        end
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
        expect(output).to include("Created slices/main/templates/users/index.html.erb")
      end
    end

    context "with existing view file" do
      let(:file_path) { "slices/main/views/users/index.rb" }

      before do
        within_application_directory do
          fs.mkdir("slices/main")
          fs.write(file_path, "existing content")
        end
      end

      it "exits with error message" do
        expect do
          within_application_directory { subject.call(name: "users.index", slice: "main") }
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
      end
    end

    context "with existing template file" do
      let(:file_path) { "slices/main/templates/users/index.html.erb" }

      before do
        within_application_directory do
          fs.mkdir("slices/main")
          fs.write(file_path, "existing content")
        end
      end

      it "raises error" do
        within_application_directory do
          expect do
            subject.call(name: "users.index", slice: "main")
          end.to raise_error SystemExit do |exception|
            expect(exception.status).to eq 1
            expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
          end
        end
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
