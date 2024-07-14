# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Generate::Relation, :app do
  subject { described_class.new(fs: fs, inflector: inflector, out: out) }

  let(:out) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { Hanami.app.namespace }
  let(:dir) { inflector.underscore(app) }

  def output
    out.string
  end

  context "generating for app" do
    describe "without namespace" do
      it "generates a relation and pluralizes name properly" do
        subject.call(name: "book")

        relation_file = <<~EXPECTED
          # frozen_string_literal: true

          module Test
            module Relations
              class Books < Test::DB::Relation
              end
            end
          end
        EXPECTED

        expect(fs.read("app/relations/books.rb")).to eq(relation_file)
        expect(output).to include("Created app/relations/books.rb")
      end

      it "generates a relation and doesn't pluralize if they want to add a _relation suffix" do
        subject.call(name: "book_relation")

        relation_file = <<~EXPECTED
          # frozen_string_literal: true

          module Test
            module Relations
              class BookRelation < Test::DB::Relation
              end
            end
          end
        EXPECTED

        expect(fs.read("app/relations/book_relation.rb")).to eq(relation_file)
        expect(output).to include("Created app/relations/book_relation.rb")
      end
    end

    it "generates a relation in a namespace with default separator" do
      subject.call(name: "books.drafts")

      relation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Relations
            module Books
              class Drafts < Test::DB::Relation
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("app/relations/books/drafts.rb")).to eq(relation_file)
      expect(output).to include("Created app/relations/books/drafts.rb")
    end

    it "generates an relation in a namespace with slash separators" do
      subject.call(name: "books/published_books")

      relation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Relations
            module Books
              class PublishedBooks < Test::DB::Relation
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("app/relations/books/published_books.rb")).to eq(relation_file)
      expect(output).to include("Created app/relations/books/published_books.rb")
    end
  end

  context "generating for a slice" do
    it "generates a relation and pluralizes name properly" do
      fs.mkdir("slices/main")
      subject.call(name: "book", slice: "main")

      relation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Main
          module Relations
            class Books < Main::DB::Relation
            end
          end
        end
      EXPECTED

      expect(fs.read("slices/main/relations/books.rb")).to eq(relation_file)
      expect(output).to include("Created slices/main/relations/books.rb")
    end

    it "generates a relation in a nested namespace" do
      fs.mkdir("slices/main")
      subject.call(name: "book.drafts", slice: "main")

      relation_file = <<~EXPECTED
        # frozen_string_literal: true

        module Main
          module Relations
            module Book
              class Drafts < Main::DB::Relation
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("slices/main/relations/book/drafts.rb")).to eq(relation_file)
      expect(output).to include("Created slices/main/relations/book/drafts.rb")
    end
  end
end
