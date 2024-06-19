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
      subject.call(name: "operations/add_book")

      operation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Operations
            class AddBook < Test::Operation
              def call
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
          module Admin
            module Books
              class Add < Test::Operation
                def call
                end
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("app/admin/books/add.rb")).to eq(operation_file)
      expect(output).to include("Created app/admin/books/add.rb")
    end

    it "generates an operation in a deep namespace with slash separator" do
      subject.call(name: "admin/books/add")

      operation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Admin
            module Books
              class Add < Test::Operation
                def call
                end
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("app/admin/books/add.rb")).to eq(operation_file)
      expect(output).to include("Created app/admin/books/add.rb")
    end

    it "outputs an error if trying to generate an operation without a separator" do
      expect {
        subject.call(name: "add_book")
      }.to raise_error(Hanami::CLI::NameNeedsNamespaceError).with_message(
        "Failed to create operation `add_book'. " \
        "This would create the operation directly in the `app/' folder. " \
        "Instead, you should provide a namespace for the folder where this operation will live. " \
        "NOTE: We recommend giving it a name that's specific to your domain, " \
        "but you can also use `operations.add_book' in the meantime if you're unsure."
      )
      expect(fs.exist?("app/add_book.rb")).to be(false)
    end
  end

  context "generating for a slice" do
    it "generates a operation" do
      fs.mkdir("slices/main")
      subject.call(name: "operations.add_book", slice: "main")

      operation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Main
          module Operations
            class AddBook < Main::Operation
              def call
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("slices/main/operations/add_book.rb")).to eq(operation_file)
      expect(output).to include("Created slices/main/operations/add_book.rb")
    end

    it "generates a operation in a deep namespace with default separator" do
      fs.mkdir("slices/main")
      subject.call(name: "admin.books.add", slice: "main")

      operation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Main
          module Admin
            module Books
              class Add < Main::Operation
                def call
                end
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("slices/main/admin/books/add.rb")).to eq(operation_file)
      expect(output).to include("Created slices/main/admin/books/add.rb")
    end

    it "outputs an error if trying to generate an operation without a separator" do
      fs.mkdir("slices/main")
      expect {
        subject.call(name: "add_book", slice: "main")
      }.to raise_error(Hanami::CLI::NameNeedsNamespaceError).with_message(
        "Failed to create operation `add_book'. " \
        "This would create the operation directly in the `slices/main/' folder. " \
        "Instead, you should provide a namespace for the folder where this operation will live. " \
        "NOTE: We recommend giving it a name that's specific to your domain, " \
        "but you can also use `operations.add_book' in the meantime if you're unsure."
      )
      expect(fs.exist?("app/add_book.rb")).to be(false)
    end
  end
end
