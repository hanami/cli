# frozen_string_literal: true

require "hanami"
require "byebug"

RSpec.describe Hanami::CLI::Commands::App::Generate::View, :app do
  subject { described_class.new(fs: fs, inflector: inflector, out: out) }

  let(:out) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { Hanami.app }
  let(:dir) { 'test' }
  let(:slice) { "main" }

  def output
    out.rewind && out.read.chomp
  end

  describe "slice detection from current working directory" do

    # Need to stub current working directory. fs.pwd returns only the name of the current directory, not the full path
    # Also the reason why Dir.pwd is used instead of fs.pwd, cause Dir.pwd returns the full path
    # Also need to stub app.root to return the path to the test app, otherwise it returns the location of the test app
    before { allow(Dir).to receive(:pwd).and_return("#{dir}/slices/#{slice}") }

    it "detects the slice based on the current working directory" do
      within_application_directory do
        expect(fs.pwd).to eq("test")
        prepare_slice!
        expect(fs.directory?("slices/#{slice}")).to be true
        fs.chdir("slices/#{slice}") do
          expect(fs.pwd).to eq("main")
          subject.call(name: "users.index")
        end

        expect(fs.exist?("slices/main/views/users/index.rb")).to be true
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

  def prepare_slice!
    fs.mkdir("slices/#{slice}")
    routes = <<~CODE
      # frozen_string_literal: true

      require "hanami/routes"

      module #{app}
        class Routes < Hanami::Routes
          root { "Hello from Hanami" }

          slice :#{slice}, at: "/#{slice}" do
          end
        end
      end
    CODE

    fs.write("config/routes.rb", routes)
  end
end
