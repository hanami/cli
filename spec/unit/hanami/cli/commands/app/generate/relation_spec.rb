# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Generate::Relation, "#call", :app_integration do
  subject { described_class.new(out: out, err: err) }

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  def output = out.string

  def error_output = err.string.chomp

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
      let(:file_path) { "app/relations/books.rb" }

      before do
        write file_path, "existing content"
      end

      it "exits with error message" do
        expect do
          subject.call(name: "books")
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
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

    context "with existing file" do
      let(:file_path) { "slices/main/relations/books.rb" }

      before do
        write file_path, "existing content"
      end

      it "exits with error message" do
        expect do
          subject.call(name: "books", slice: "main")
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
      end
    end
  end

  context "with capitalized relation name" do
    it "generates the relation with downcased schema name" do
      subject.call(name: "Entries")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module TestApp
          module Relations
            class Entries < TestApp::DB::Relation
              schema :entries, infer: true
            end
          end
        end
      RUBY

      expect(Hanami.app.root.join("app/relations/entries.rb").read).to eq(relation_file)
      expect(output).to include("Created app/relations/entries.rb")
    end
  end
end
