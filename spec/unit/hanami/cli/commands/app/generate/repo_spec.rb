# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Generate::Repo, :app do
  subject { described_class.new(fs: fs, inflector: inflector, out: out) }

  let(:out) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { Hanami.app.namespace }
  let(:dir) { inflector.underscore(app) }

  def output
    out.rewind && out.read.chomp
  end

  context "generating for app" do
    describe "without namespace" do
      it "generates a repo and pluralizes name properly" do
        subject.call(name: "book")

        repo_file = <<~EXPECTED
          # frozen_string_literal: true

          module Test
            module Repos
              class BooksRepo < Test::DB::Repo
              end
            end
          end
        EXPECTED

        expect(fs.read("app/repos/books_repo.rb")).to eq(repo_file)
        expect(output).to include("Created app/repos/books_repo.rb")
      end

      it "passed through repo name if repo_suffix" do
        subject.call(name: "book_repo")

        repo_file = <<~EXPECTED
          # frozen_string_literal: true

          module Test
            module Repos
              class BookRepo < Test::DB::Repo
              end
            end
          end
        EXPECTED

        expect(fs.read("app/repos/book_repo.rb")).to eq(repo_file)
        expect(output).to include("Created app/repos/book_repo.rb")
      end
    end

    it "generates a repo in a deep namespace with default separator" do
      subject.call(name: "books.drafts_repo")

      repo_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Repos
            module Books
              class DraftsRepo < Test::DB::Repo
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("app/repos/books/drafts_repo.rb")).to eq(repo_file)
      expect(output).to include("Created app/repos/books/drafts_repo.rb")
    end

    it "generates an repo in a deep namespace with slash separators" do
      subject.call(name: "books/published_repo")

      repo_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Repos
            module Books
              class PublishedRepo < Test::DB::Repo
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("app/repos/books/published_repo.rb")).to eq(repo_file)
      expect(output).to include("Created app/repos/books/published_repo.rb")
    end
  end

  context "generating for a slice" do
    it "generates a repo in a top-level namespace, with recommendation" do
      fs.mkdir("slices/main")
      subject.call(name: "book", slice: "main")

      repo_file = <<~EXPECTED
        # frozen_string_literal: true

        module Main
          module Repos
            class BooksRepo < Main::DB::Repo
            end
          end
        end
      EXPECTED

      expect(fs.read("slices/main/repos/books_repo.rb")).to eq(repo_file)
      expect(output).to include("Created slices/main/repos/books_repo.rb")
    end

    it "generates a repo in a nested namespace" do
      fs.mkdir("slices/main")
      subject.call(name: "book.draft", slice: "main")

      repo_file = <<~EXPECTED
        # frozen_string_literal: true

        module Main
          module Repos
            module Book
              class DraftsRepo < Main::DB::Repo
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("slices/main/repos/book/drafts_repo.rb")).to eq(repo_file)
      expect(output).to include("Created slices/main/repos/book/drafts_repo.rb")
    end
  end
end
