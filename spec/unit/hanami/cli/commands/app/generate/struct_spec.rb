# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Generate::Struct, :app do
  subject { described_class.new(fs: fs, out: out, err: err) }

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:app) { Hanami.app.namespace }

  def output = out.string.chomp

  def error_output = err.string.chomp

  context "generating for app" do
    it "generates a struct without a namespace" do
      subject.call(name: "book")

      struct_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Structs
            class Book < Test::DB::Struct
            end
          end
        end
      EXPECTED

      expect(fs.read("app/structs/book.rb")).to eq(struct_file)
      expect(output).to include("Created app/structs/book.rb")
    end

    it "generates a struct in a namespace with default separator" do
      subject.call(name: "book.book_draft")

      struct_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Structs
            module Book
              class BookDraft < Test::DB::Struct
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("app/structs/book/book_draft.rb")).to eq(struct_file)
      expect(output).to include("Created app/structs/book/book_draft.rb")
    end

    it "generates an struct in a deep namespace with slash separators" do
      subject.call(name: "book/published/hardcover")

      struct_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Structs
            module Book
              module Published
                class Hardcover < Test::DB::Struct
                end
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("app/structs/book/published/hardcover.rb")).to eq(struct_file)
      expect(output).to include("Created app/structs/book/published/hardcover.rb")
    end

    context "with existing file" do
      let(:file_path) { "app/structs/book/published/hardcover.rb" }

      before do
        fs.write(file_path, "existing content")
      end

      it "exits with error message" do
        expect do
          subject.call(name: "book/published/hardcover")
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
      end
    end
  end

  context "generating for a slice" do
    it "generates a struct in a top-level namespace" do
      fs.mkdir("slices/main")
      subject.call(name: "book", slice: "main")

      struct_file = <<~EXPECTED
        # frozen_string_literal: true

        module Main
          module Structs
            class Book < Main::DB::Struct
            end
          end
        end
      EXPECTED

      expect(fs.read("slices/main/structs/book.rb")).to eq(struct_file)
      expect(output).to include("Created slices/main/structs/book.rb")
    end

    it "generates a struct in a nested namespace" do
      fs.mkdir("slices/main")
      subject.call(name: "book.draft_book", slice: "main")

      struct_file = <<~EXPECTED
        # frozen_string_literal: true

        module Main
          module Structs
            module Book
              class DraftBook < Main::DB::Struct
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("slices/main/structs/book/draft_book.rb")).to eq(struct_file)
      expect(output).to include("Created slices/main/structs/book/draft_book.rb")
    end

    context "with existing file" do
      let(:file_path) { "slices/main/structs/book/draft_book.rb" }

      before do
        fs.write(file_path, "existing content")
      end

      it "exits with error message" do
        expect do
          subject.call(name: "book.draft_book", slice: "main")
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
      end
    end
  end

  context "with capitalized struct name" do
    it "generates the struct with downcased filename" do
      subject.call(name: "Entry")

      struct_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Structs
            class Entry < Test::DB::Struct
            end
          end
        end
      EXPECTED

      expect(fs.read("app/structs/entry.rb")).to eq(struct_file)
      expect(output).to include("Created app/structs/entry.rb")
    end

    context "when nested with dot syntax" do
      it "generates the struct with downcased filename" do
        subject.call(name: "book.Entry")

        struct_file = <<~EXPECTED
          # frozen_string_literal: true

          module Test
            module Structs
              module Book
                class Entry < Test::DB::Struct
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("app/structs/book/entry.rb")).to eq(struct_file)
        expect(output).to include("Created app/structs/book/entry.rb")
      end
    end

    context "when nested with slash syntax" do
      it "generates the struct with downcased filename" do
        subject.call(name: "book/Entry")

        struct_file = <<~EXPECTED
          # frozen_string_literal: true

          module Test
            module Structs
              module Book
                class Entry < Test::DB::Struct
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("app/structs/book/entry.rb")).to eq(struct_file)
        expect(output).to include("Created app/structs/book/entry.rb")
      end
    end
  end
end
