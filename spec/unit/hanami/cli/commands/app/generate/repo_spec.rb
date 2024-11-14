# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Generate::Repo, :app do
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
      it "generates a repo and singularizes name properly" do
        subject.call(name: "books")

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

      it "passed through repo name if repo_ suffix is preent" do
        subject.call(name: "books_repo")

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
    end

    it "generates a repo in a namespace with default separator" do
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
      subject.call(name: "books/published/hardcover_repo")

      repo_file = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Repos
            module Books
              module Published
                class HardcoverRepo < Test::DB::Repo
                end
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("app/repos/books/published/hardcover_repo.rb")).to eq(repo_file)
      expect(output).to include("Created app/repos/books/published/hardcover_repo.rb")
    end

    context "with existing file" do
      before do
        fs.write("app/repos/book_repo.rb", "existing content")
      end

      it "raises error" do
        expect {
          subject.call(name: "books")
        }.to raise_error(Hanami::CLI::FileAlreadyExistsError)
      end
    end
  end

  context "generating for a slice" do
    it "generates a repo and singularizes name properly" do
      fs.mkdir("slices/main")
      subject.call(name: "books", slice: "main")

      repo_file = <<~EXPECTED
        # frozen_string_literal: true

        module Main
          module Repos
            class BookRepo < Main::DB::Repo
            end
          end
        end
      EXPECTED

      expect(fs.read("slices/main/repos/book_repo.rb")).to eq(repo_file)
      expect(output).to include("Created slices/main/repos/book_repo.rb")
    end

    it "generates a repo in a nested namespace" do
      fs.mkdir("slices/main")
      subject.call(name: "book.draft", slice: "main")

      repo_file = <<~EXPECTED
        # frozen_string_literal: true

        module Main
          module Repos
            module Book
              class DraftRepo < Main::DB::Repo
              end
            end
          end
        end
      EXPECTED

      expect(fs.read("slices/main/repos/book/draft_repo.rb")).to eq(repo_file)
      expect(output).to include("Created slices/main/repos/book/draft_repo.rb")
    end

    context "with existing file" do
      before do
        fs.write("slices/main/repos/book_repo.rb", "existing content")
      end

      it "raises error" do
        expect {
          subject.call(name: "books", slice: "main")
        }.to raise_error(Hanami::CLI::FileAlreadyExistsError)
      end
    end
  end
end
