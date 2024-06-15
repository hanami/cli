# frozen_string_literal: true

require "hanami"
require "ostruct"

RSpec.describe Hanami::CLI::Commands::App::Generate::Operation, :app do
  subject { described_class.new(fs: fs, inflector: inflector, generator: generator) }

  let(:out) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:generator) { Hanami::CLI::Generators::App::Operation.new(fs: fs, inflector: inflector) }
  let(:app) { Hanami.app.namespace }
  let(:dir) { inflector.underscore(app) }

  def output
    out.rewind && out.read.chomp
  end

  context "generating for app" do
    it "generates an operation" do
      subject.call(name: "add_book")

      # operation
      operation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Operations

            class AddBook < Test::Operation
            end

          end
        end
      EXPECTED

      expect(fs.read("app/operations/add_book.rb")).to eq(operation_file)
      expect(output).to include("Created app/operations/add_book.rb")
    end

    xit "add one for slashes? it does compact module syntax... but why?"

    it "generates a operation in a deep namespace" do
      subject.call(name: "external.books.add")

      # view
      operation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Operations
            module External
              module Books
                class Add < Test::Operation
                end
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("app/operations/external/books/add.rb")).to eq(operation_file)
      expect(output).to include("Created app/operations/external/books/add.rb")
    end
  end

  context "generating for a slice" do
    it "generates a operation in a top-level namespace" do
      fs.mkdir("slices/main")
      subject.call(name: "add_book", slice: "main")

      # operation
      operation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Main
          module Operations

            class AddBook < Main::Operation
            end

          end
        end
      EXPECTED

      expect(fs.read("slices/main/operations/add_book.rb")).to eq(operation_file)
      expect(output).to include("Created slices/main/operations/add_book.rb")
    end
  end
end
