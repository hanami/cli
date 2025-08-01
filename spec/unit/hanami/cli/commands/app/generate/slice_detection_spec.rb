# frozen_string_literal: true

require "hanami"
require "byebug"

RSpec.describe "slice detection", :app do

  subject { generator_class.new(fs: fs, inflector: inflector, out: out) }

  let(:generator_class) { Hanami::CLI::Commands::App::Generate::View }
  let(:out) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { Hanami.app }
  let(:dir) { 'test' }
  let(:slice) { "main" }
  let(:slice_registrar) { instance_double(Hanami::SliceRegistrar) }
  let(:generator) { instance_double("Generator") }

  def output
    out.rewind && out.read.chomp
  end

  describe "slice detection from current working directory" do

    # Need to stub current working directory. fs.pwd returns only the name of the current directory, not the full path
    # Also the reason why Dir.pwd is used instead of fs.pwd, cause Dir.pwd returns the full path
    # Also need to stub app.root to return the path to the test app, otherwise it returns the location of the test app
    # Then we also have to stub slice_registrar because it is the best way to detect slices but also one that would be very hard to properly setup with test app
    before do
      allow(Dir).to receive(:pwd).and_return("#{dir}/slices/#{slice}")
      allow(app).to receive(:root).and_return(Pathname.new(dir))
      allow(slice_registrar).to receive(:load_slices).and_return([])
      allow(slice_registrar).to receive(:keys).and_return([slice.to_sym])
      allow(slice_registrar).to receive(:[]).with(slice.to_sym).and_return(:mocked_value)
      allow(app).to receive(:slices).and_return(slice_registrar)

      allow(subject).to receive(:generator).and_return(generator)
      allow(generator).to receive(:call)
    end

    it "detects the slice based on the current working directory" do
      within_application_directory do
        expect(fs.pwd).to eq("test")
        prepare_slice!
        expect(fs.directory?("slices/#{slice}")).to be true
        fs.chdir("slices/#{slice}") do
          expect(fs.pwd).to eq("main")
          subject.call(name: "users.index")
        end

        expect(generator).to have_received(:call).with(key: "users.index", namespace: slice, base_path: "slices/#{slice}")
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
