# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Generate::Struct, :app do
  subject { described_class.new(fs: fs, inflector: inflector, out: out) }

  let(:out) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { Hanami.app.namespace }

  def output
    out.string.chomp
  end

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
      before do
        fs.write("app/structs/book/published/hardcover.rb", "existing content")
      end

      it "raises error" do
        expect {
          subject.call(name: "book/published/hardcover")
        }.to raise_error(Hanami::CLI::FileAlreadyExistsError)
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
      before do
        fs.write("slices/main/structs/book/draft_book.rb", "existing content")
      end

      it "raises error" do
        expect {
          subject.call(name: "book.draft_book", slice: "main")
        }.to raise_error(Hanami::CLI::FileAlreadyExistsError)
      end
    end
  end
end
