# frozen_string_literal: true

require "hanami"

RSpec.describe "slice detection", :app_integration do
  subject(:cmd) { Hanami::CLI::Commands::App::Generate::View.new(out: out) }

  let(:out) { StringIO.new }
  def output
    out.rewind && out.read.chomp
  end

  before do
    with_directory(@app_dir) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "slices/main/.keep", ""
      write "slices/admin/.keep", ""
      write "slices/admin/slices/search/.keep", ""

      require "hanami/prepare"
    end
  end

  around do |example|
    @app_dir = make_tmp_directory
    orig_cwd = Dir.pwd

    # Use non-block form of chdir to avoid "conflicting chdir" warnings when we do it inside the
    # examples
    Dir.chdir(@app_dir)
    example.call
    Dir.chdir(orig_cwd)
  end

  describe "slice detection from current working directory" do
    it "detects the slice based on the current working directory" do
      Dir.chdir("slices/main") do
        subject.call(name: "showcase")
      end

      expect(File.exist?("slices/main/views/showcase.rb")).to be true
    end

    context "with deeply nested slices existing" do
      it "determines the nested slice when inside of it" do
        Dir.chdir("slices/admin/slices/search") do
          subject.call(name: "panel")
        end

        expect(File.exist?("slices/admin/slices/search/views/panel.rb")).to be true
      end

      it "still determines the parent slice when inside of it" do
        Dir.chdir("slices/main") do
          subject.call(name: "bookcase")
        end

        expect(File.exist?("slices/main/views/bookcase.rb")).to be true
      end
    end
  end

  context "when --slice option is provided" do
    it "in child slice - respects the --slice option - overwrites slice detection" do
      Dir.chdir("slices/admin/slices/search") do
        subject.call(name: "bookcase", slice: "main")
      end

      expect(File.exist?("slices/main/views/bookcase.rb")).to be true
    end

    it "in sibling slice - respects the --slice option - overwrites slice detection" do
      Dir.chdir("slices/main") do
        subject.call(name: "shop", slice: "admin")
      end

      expect(File.exist?("slices/admin/views/shop.rb")).to be true
    end
  end

  context "when working outside slice directory" do
    it "uses app namespace when not in a slice directory" do
      subject.call(name: "important_view")

      expect(File.exist?("app/views/important_view.rb")).to be true
    end
  end
end
