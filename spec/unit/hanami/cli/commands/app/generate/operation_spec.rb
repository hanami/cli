# frozen_string_literal: true

require "hanami"

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

      operation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Operations
            class AddBook < Test::Operation
              def call(input)
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("app/operations/add_book.rb")).to eq(operation_file)
      expect(output).to include("Created app/operations/add_book.rb")
    end

    it "generates a operation in a deep namespace with default separator" do
      subject.call(name: "admin.books.add")

      operation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Operations
            module Admin
              module Books
                class Add < Test::Operation
                  def call(input)
                  end
                end
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("app/operations/admin/books/add.rb")).to eq(operation_file)
      expect(output).to include("Created app/operations/admin/books/add.rb")
    end

    it "generates an operation in a deep namespace with slash separators" do
      subject.call(name: "admin/books/add")

      operation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Operations
            module Admin
              module Books
                class Add < Test::Operation
                  def call(input)
                  end
                end
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("app/operations/admin/books/add.rb")).to eq(operation_file)
      expect(output).to include("Created app/operations/admin/books/add.rb")
    end
  end

  context "generating for a slice" do
    it "generates a operation in a top-level namespace" do
      fs.mkdir("slices/main")
      subject.call(name: "add_book", slice: "main")

      operation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Main
          module Operations
            class AddBook < Main::Operation
              def call(input)
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("slices/main/operations/add_book.rb")).to eq(operation_file)
      expect(output).to include("Created slices/main/operations/add_book.rb")
    end
  end
end
