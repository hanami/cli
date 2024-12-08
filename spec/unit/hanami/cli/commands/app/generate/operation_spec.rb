# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Generate::Operation, :app do
  subject { described_class.new(fs: fs, inflector: inflector, out: out, err: err) }

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { Hanami.app.namespace }

  def output
    out.string.chomp
  end

  def error_output = err.string.chomp

  context "generating for app" do
    it "generates an operation without a namespace, with a recommendation" do
      subject.call(name: "add_book")

      operation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          class AddBook < Test::Operation
            def call
            end
          end
        end
      EXPECTED

      expect(fs.read("app/add_book.rb")).to eq(operation_file)
      expect(output).to include("Created app/add_book.rb")
      expect(output).to include(
        "  Note: We generated a top-level operation. " \
        "To generate into a directory, add a namespace: `my_namespace.add_book`"
      )
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

    it "generates an operation in a deep namespace with slash separators" do
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

    context "with existing file" do
      before do
        fs.write("app/admin/books/add.rb", "existing content")
      end

      it "exits with error message" do
        expect do
          subject.call(name: "admin.books.add")
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq "Cannot overwrite existing file: `app/admin/books/add.rb`"
        end
      end
    end
  end

  context "generating for a slice" do
    it "generates a operation in a top-level namespace, with recommendation" do
      fs.mkdir("slices/main")
      subject.call(name: "add_book", slice: "main")

      operation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Main
          class AddBook < Main::Operation
            def call
            end
          end
        end
      EXPECTED

      expect(fs.read("slices/main/add_book.rb")).to eq(operation_file)
      expect(output).to include("Created slices/main/add_book.rb")
      expect(output).to include(
        "  Note: We generated a top-level operation. " \
        "To generate into a directory, add a namespace: `my_namespace.add_book`"
      )
    end

    it "generates a operation in a nested namespace" do
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

    context "with existing file" do
      before do
        fs.mkdir("slices/main")
        fs.write("slices/main/admin/books/add.rb", "existing content")
      end

      it "exits with error message" do
        expect do
          subject.call(name: "admin.books.add", slice: "main")
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq "Cannot overwrite existing file: `slices/main/admin/books/add.rb`"
        end
      end
    end
  end
end
