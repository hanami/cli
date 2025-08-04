# frozen_string_literal: true

require "hanami"

RSpec.describe "slice detection", :app_integration do
  subject(:cmd) { Hanami::CLI::Commands::App::Generate::View.new(inflector: inflector, out: out) }

  let(:inflector) { Dry::Inflector.new }
  let(:out) { StringIO.new }
  def output
    out.rewind && out.read.chomp
  end

  describe "slice detection from current working directory" do
    it "detects the slice based on the current working directory" do
      in_main_app_directory do
        in_slice_directory do
          subject.call(name: "showcase")
        end
        expect(File.exist?("slices/main/views/showcase.rb")).to be true
      end
    end

    context "with deeply nested slices existing" do
      let(:nested_slice) { "superadmin" }

      it "determines the nested slice when inside of it" do
        in_main_app_directory do
          in_slice_directory do
            Dir.chdir("slices/admin") do
              subject.call(name: "panel")
            end
          end

          expect(File.exist?("slices/main/slices/admin/views/panel.rb")).to be true
        end
      end

      it "still determines the parent slice when inside of it" do
        in_main_app_directory do
          in_slice_directory do
            subject.call(name: "bookcase")
          end

          expect(File.exist?("slices/main/views/bookcase.rb")).to be true
        end
      end
    end

    context "when --slice option is provided" do
      it "in child slice - respects the --slice option - overwrites slice detection" do
        in_main_app_directory do
          in_slice_directory do
            Dir.chdir("slices/admin") do
              subject.call(name: "bookcase", slice: "main")
            end
          end

          expect(File.exist?("slices/main/views/bookcase.rb")).to be true
        end
      end

      it "in sibling slice - respects the --slice option - overwrites slice detection" do
        with_directory(@dir = make_tmp_directory) do
          write "config/app.rb", <<~RUBY
            module TestApp
              class App < Hanami::App
              end
            end
          RUBY

          write "slices/main/.keep", ""
          write "slices/client/.keep", ""

          require "hanami/setup"
          before_prepare if respond_to?(:before_prepare)
          require "hanami/prepare"
        end

        Dir.chdir("#{@dir}/slices/main") do
          subject.call(name: "shop", slice: "client")
        end
        expect(File.exist?("#{@dir}/slices/client/views/shop.rb")).to be true
      end
    end

    context "when working outside slice directory" do
      it "uses app namespace when not in a slice directory" do
        in_main_app_directory do
          subject.call(name: "important_view")
          expect(File.exist?("app/views/important_view.rb")).to be true
        end
      end
    end
  end

  private

  def in_slice_directory(&)
    Dir.chdir("slices/main") do
      yield if block_given?
    end
  end

  def in_main_app_directory(&)
    with_directory(@dir = make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "slices/main/.keep", ""
      write "slices/main/slices/admin/.keep", ""

      require "hanami/setup"
      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end

    Dir.chdir(@dir)
    yield if block_given?
  end
end
