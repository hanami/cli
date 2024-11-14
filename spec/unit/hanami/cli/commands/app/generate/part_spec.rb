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
    context "without base part" do
      it "generates base part and the part" do
        within_application_directory do
          subject.call(name: "user")

          # base_part
          base_part = <<~EXPECTED
            # auto_register: false
            # frozen_string_literal: true

            module Test
              module Views
                class Part < Hanami::View::Part
                end
              end
            end
          EXPECTED

          expect(fs.read("app/views/part.rb")).to eq(base_part)
          expect(output).to include("Created app/views/part.rb")

          # part
          part = <<~EXPECTED
            # auto_register: false
            # frozen_string_literal: true

            module Test
              module Views
                module Parts
                  class User < Test::Views::Part
                  end
                end
              end
            end
          EXPECTED

          expect(fs.read("app/views/parts/user.rb")).to eq(part)
          expect(output).to include("Created app/views/parts/user.rb")
        end
      end

      context "with existing file" do
        before do
          within_application_directory do
            fs.write("app/views/parts/user.rb", "existing content")
          end
        end

        it "raises error" do
          within_application_directory do
            expect {
              subject.call(name: "user")
            }.to raise_error(Hanami::CLI::FileAlreadyExistsError)
          end
        end
      end
    end

    context "with base part" do
      it "generates the part" do
        within_application_directory do
          # base_part
          base_part = <<~EXPECTED
            # auto_register: false
            # frozen_string_literal: true

            module Test
              module Views
                class Part < Hanami::View::Part
                end
              end
            end
          EXPECTED
          fs.write("app/views/part.rb", base_part)

          subject.call(name: "user")

          # part
          part = <<~EXPECTED
            # auto_register: false
            # frozen_string_literal: true

            module Test
              module Views
                module Parts
                  class User < Test::Views::Part
                  end
                end
              end
            end
          EXPECTED

          expect(fs.read("app/views/parts/user.rb")).to eq(part)
          expect(output).to include("Created app/views/parts/user.rb")

          # This is still printed because the fs.write above still prints
          # expect(output).to_not include("Created app/views/part.rb")
        end
      end
    end
  end

  context "generating for a slice" do
    context "without base part" do
      it "generates base part and the part" do
        within_application_directory do
          fs.mkdir("slices/main")
          subject.call(name: "user", slice: "main")

          # app_base_part
          app_base_part = <<~EXPECTED
            # auto_register: false
            # frozen_string_literal: true

            module Test
              module Views
                class Part < Hanami::View::Part
                end
              end
            end
          EXPECTED

          expect(fs.read("app/views/part.rb")).to eq(app_base_part)
          expect(output).to include("Created app/views/part.rb")

          # base_part
          base_part = <<~EXPECTED
            # auto_register: false
            # frozen_string_literal: true

            module Main
              module Views
                class Part < Test::Views::Part
                end
              end
            end
          EXPECTED

          expect(fs.read("slices/main/views/part.rb")).to eq(base_part)
          expect(output).to include("Created slices/main/views/part.rb")

          # part
          part = <<~EXPECTED
            # auto_register: false
            # frozen_string_literal: true

            module Main
              module Views
                module Parts
                  class User < Main::Views::Part
                  end
                end
              end
            end
          EXPECTED

          expect(fs.read("slices/main/views/parts/user.rb")).to eq(part)
          expect(output).to include("Created slices/main/views/parts/user.rb")
        end
      end
    end

    context "with base part" do
      it "generates the part" do
        within_application_directory do
          fs.mkdir("slices/main")

          # base_part
          base_part = <<~EXPECTED
            # auto_register: false
            # frozen_string_literal: true

            module Main
              module Views
                class Part < Test::Views::Part
                end
              end
            end
          EXPECTED
          fs.write("slices/main/views/part.rb", base_part)

          subject.call(name: "user", slice: "main")

          # part
          part = <<~EXPECTED
            # auto_register: false
            # frozen_string_literal: true

            module Main
              module Views
                module Parts
                  class User < Main::Views::Part
                  end
                end
              end
            end
          EXPECTED

          expect(fs.read("slices/main/views/parts/user.rb")).to eq(part)
          expect(output).to include("Created slices/main/views/parts/user.rb")

          # This is still printed because the fs.write above still prints
          # expect(output).to_not include("Created slices/main/views/part.rb")
        end
      end
    end

    context "with existing file" do
      before do
        within_application_directory do
          fs.mkdir("slices/main")
          fs.write("slices/main/views/parts/user.rb", "existing content")
        end
      end

      it "raises error" do
        within_application_directory do
          expect {
            subject.call(name: "user", slice: "main")
          }.to raise_error(Hanami::CLI::FileAlreadyExistsError)
        end
      end
    end

    context "with missing slice" do
      it "raises error" do
        within_application_directory do
          expect { subject.call(name: "user", slice: "foo") }.to raise_error(Hanami::CLI::MissingSliceError)
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
