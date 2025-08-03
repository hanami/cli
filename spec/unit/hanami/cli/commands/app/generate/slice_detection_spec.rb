# frozen_string_literal: true

RSpec.describe "Slice detection for generate commands", :app_integration do
  subject(:command) {
    Hanami::CLI::Commands::App::Generate::Operation.new(
      inflector: inflector,
      out: out
    )
  }

  let(:out) { StringIO.new }
  def output = out.string.chomp
  let(:inflector) { Dry::Inflector.new }

  before do
    with_directory(@dir = make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "slices/main/.keep", ""

      require "hanami/setup"
      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end

    Dir.chdir(@dir)
  end

  it "detects the slice based on the current working directory" do
    Dir.chdir("slices/main") do
      command.call(name: "add_book")
    end

    expect(File.exist?("slices/main/add_book.rb")).to be true
  end
end
