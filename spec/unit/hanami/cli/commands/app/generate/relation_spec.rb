# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Generate::Relation, :app do
  subject { described_class.new(fs: fs, inflector: inflector, out: out) }

  let(:out) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { Hanami.app.namespace }

  def output
    out.string
  end

  context "generating for app" do
    describe "without namespace" do
      it "generates a relation" do
        subject.call(name: "books")

        relation_file = <<~RUBY
          # frozen_string_literal: true

          module Test
            module Relations
              class Books < Test::DB::Relation
                schema :books, infer: true
              end
            end
          end
        RUBY

        expect(fs.read("app/relations/books.rb")).to eq(relation_file)
        expect(output).to include("Created app/relations/books.rb")
      end
    end

    it "generates a relation in a namespace with default separator" do
      subject.call(name: "books.drafts")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module Test
          module Relations
            module Books
              class Drafts < Test::DB::Relation
                schema :drafts, infer: true
              end
            end
          end
        end
      RUBY

      expect(fs.read("app/relations/books/drafts.rb")).to eq(relation_file)
      expect(output).to include("Created app/relations/books/drafts.rb")
    end

    it "generates an relation in a namespace with slash separators" do
      subject.call(name: "books/published_books")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module Test
          module Relations
            module Books
              class PublishedBooks < Test::DB::Relation
                schema :published_books, infer: true
              end
            end
          end
        end
      RUBY

      expect(fs.read("app/relations/books/published_books.rb")).to eq(relation_file)
      expect(output).to include("Created app/relations/books/published_books.rb")
    end
  end

  context "generating for a slice" do
    it "generates a relation" do
      fs.mkdir("slices/main")
      subject.call(name: "books", slice: "main")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module Main
          module Relations
            class Books < Main::DB::Relation
              schema :books, infer: true
            end
          end
        end
      RUBY

      expect(fs.read("slices/main/relations/books.rb")).to eq(relation_file)
      expect(output).to include("Created slices/main/relations/books.rb")
    end

    it "generates a relation in a nested namespace" do
      fs.mkdir("slices/main")
      subject.call(name: "book.drafts", slice: "main")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module Main
          module Relations
            module Book
              class Drafts < Main::DB::Relation
                schema :drafts, infer: true
              end
            end
          end
        end
      RUBY

      expect(fs.read("slices/main/relations/book/drafts.rb")).to eq(relation_file)
      expect(output).to include("Created slices/main/relations/book/drafts.rb")
    end
  end
end
