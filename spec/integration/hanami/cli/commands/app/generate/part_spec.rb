# frozen_string_literal: true

require "hanami"

RSpec.describe "Hanami generate part integration", :app do
  let(:fs) { Hanami::CLI::Files.new(memory: false, out: out) }
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  subject(:command) do
    Hanami::CLI::Commands::App::Generate::Part.new(fs: fs, out: out, err: err)
  end

  def error_output = err.string.chomp

  around do |example|
    Dir.mktmpdir do |dir|
      original_dir = Dir.pwd
      Dir.chdir(dir)

      # Create a basic Hanami app structure
      fs.mkdir("app")
      fs.mkdir("config")

      routes_content = <<~RUBY
        # frozen_string_literal: true

        require "hanami/routes"

        module TestApp
          class Routes < Hanami::Routes
            root { "Hello from Hanami" }
          end
        end
      RUBY

      fs.write("config/routes.rb", routes_content)

      example.run
    ensure
      Dir.chdir(original_dir) if original_dir
    end
  end

  context "when generating parts" do
    it "creates part file successfully, with only name" do
      expect { command.call(name: "user") }.not_to raise_error

      expect(fs.exist?("app/views/parts/user.rb")).to be(true)
    end

    it "supports skip_tests parameter" do
      expect {
        command.call(name: "product", skip_tests: true)
      }.not_to raise_error

      expect(fs.exist?("app/views/parts/product.rb")).to be(true)
    end

    it "allows arbitrary keyword arguments" do
      expect {
        command.call(name: "book", extra_param: "extra_value", skip_tests: true)
      }.not_to raise_error

      expect(fs.exist?("app/views/parts/book.rb")).to be(true)
    end
  end

  context "error handling" do
    let(:file_path) { "app/views/parts/existing.rb" }

    it "handles file conflicts" do
      fs.mkdir("app/views/parts")
      fs.write(file_path, "# existing content")

      expect do
        command.call(name: "existing")
      end.to raise_error SystemExit do |exception|
        expect(exception.status).to eq 1
        expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
      end
    end
  end
end
