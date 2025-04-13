# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Generate::Relation, "#call", :app_integration do
  subject { described_class.new(inflector: inflector, out: out) }

  let(:inflector) { Dry::Inflector.new }

  let(:out) { StringIO.new }
  def output = out.string

  before do
    with_directory(@dir = make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/relations/.keep", ""

      write "slices/main/.keep", ""

      require "hanami/setup"
    end

    Dir.chdir(@dir)
  end

  context "generating for app" do
    it "generates a relation" do
      subject.call(name: "books")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module TestApp
          module Relations
            class Books < TestApp::DB::Relation
              schema :books, infer: true
            end
          end
        end
      RUBY

      expect(Hanami.app.root.join("app/relations/books.rb").read).to eq relation_file
      expect(output).to include("Created app/relations/books.rb")
    end

    it "generates a relation in a namespace with default separator" do
      subject.call(name: "books.drafts")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module TestApp
          module Relations
            module Books
              class Drafts < TestApp::DB::Relation
                schema :drafts, infer: true
              end
            end
          end
        end
      RUBY

      expect(Hanami.app.root.join("app/relations/books/drafts.rb").read).to eq(relation_file)
      expect(output).to include("Created app/relations/books/drafts.rb")
    end

    it "generates an relation in a namespace with slash separators" do
      subject.call(name: "books/published_books")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module TestApp
          module Relations
            module Books
              class PublishedBooks < TestApp::DB::Relation
                schema :published_books, infer: true
              end
            end
          end
        end
      RUBY

      expect(Hanami.app.root.join("app/relations/books/published_books.rb").read).to eq(relation_file)
      expect(output).to include("Created app/relations/books/published_books.rb")
    end

    it "deletes the redundant .keep file" do
      expect { subject.call(name: "books") }
        .to change { Hanami.app.root.join("app/relations/.keep").file? }
        .to false
    end

    it "generates a relation for gateway" do
      subject.call(name: "books", gateway: "extra")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module TestApp
          module Relations
            class Books < TestApp::DB::Relation
              gateway :extra
              schema :books, infer: true
            end
          end
        end
      RUBY

      expect(Hanami.app.root.join("app/relations/books.rb").read).to eq relation_file
      expect(output).to include("Created app/relations/books.rb")
    end

    context "with existing file" do
      before do
        write "app/relations/books.rb", "existing content"
      end

      it "raises error" do
        expect { subject.call(name: "books") }
          .to raise_error(Hanami::CLI::FileAlreadyExistsError)
      end
    end
  end

  context "generating for a slice" do
    it "generates a relation" do
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

      expect(Hanami.app.root.join("slices/main/relations/books.rb").read).to eq(relation_file)
      expect(output).to include("Created slices/main/relations/books.rb")
    end

    it "generates a relation in a nested namespace" do
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

      expect(Hanami.app.root.join("slices/main/relations/book/drafts.rb").read).to eq(relation_file)
      expect(output).to include("Created slices/main/relations/book/drafts.rb")
    end

    it "generates a relation for gateway" do
      subject.call(name: "book.drafts", slice: "main", gateway: "extra")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module Main
          module Relations
            module Book
              class Drafts < Main::DB::Relation
                gateway :extra
                schema :drafts, infer: true
              end
            end
          end
        end
      RUBY

      expect(Hanami.app.root.join("slices/main/relations/book/drafts.rb").read).to eq(relation_file)
      expect(output).to include("Created slices/main/relations/book/drafts.rb")
    end

    it "infers the slice name from input origin" do
      allow(subject).to receive(:detect_slice_from_current_directory).and_return("stuff")

      subject.call(name: "book.drafts")

      relation_file = <<~RUBY
        # frozen_string_literal: true
        
        module Stuff
          module Relations
            module Book
              class Drafts
              end
            end
          end
        end
      RUBY

      expect(Hanami.app.root.join("slices/main/relations/book/drafts.rb").read).to eq(relation_file)
      expect(output).to include("Created slices/main/relations/book/drafts.rb")
    end

    context "with existing file" do
      before do
        write "slices/main/relations/books.rb", "existing content"
      end

      it "raises error" do
        expect { subject.call(name: "books", slice: "main") }
          .to raise_error(Hanami::CLI::FileAlreadyExistsError)
      end
    end
  end
end
