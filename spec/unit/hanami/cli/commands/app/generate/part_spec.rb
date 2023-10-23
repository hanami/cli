# frozen_string_literal: true

require "hanami"
require "ostruct"

RSpec.describe Hanami::CLI::Commands::App::Generate::Part, :app do
  subject { described_class.new(fs: fs, inflector: inflector, generator: generator) }

  let(:out) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:generator) { Hanami::CLI::Generators::App::Part.new(fs: fs, inflector: inflector) }
  let(:app) { Hanami.app.namespace }
  let(:dir) { inflector.underscore(app) }

  def output
    out.rewind && out.read.chomp
  end

  context "generating for app" do
    it "generates a part in a top-level namespace" do
      within_application_directory do
        subject.call(name: "user")

        # part
        part = <<~EXPECTED
          # auto_register: false
          # frozen_string_literal: true

          module Test
            module Views
              module Parts
                class User < Test::Part
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("app/views/parts/user.rb")).to eq(part)
        expect(output).to include("Created app/views/parts/user.rb")
      end
    end
  end

  context "generating for a slice" do
    it "generates a view in a top-level namespace" do
      within_application_directory do
        fs.mkdir("slices/main")
        subject.call(name: "user", slice: "main")

        # view
        view_file = <<~EXPECTED
          # auto_register: false
          # frozen_string_literal: true

          module Main
            module Views
              module Parts
                class User < Main::Part
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("slices/main/views/parts/user.rb")).to eq(view_file)
        expect(output).to include("Created slices/main/views/parts/user.rb")
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
