# frozen_string_literal: true

require "hanami"

RSpec.describe "Hanami generate part integration", :app do
  let(:fs) { Hanami::CLI::Files.new(memory: false, out: out) }
  let(:out) { StringIO.new }

  subject(:command) do
    Hanami::CLI::Commands::App::Generate::Part.new(fs: fs, out: out)
  end

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
end
