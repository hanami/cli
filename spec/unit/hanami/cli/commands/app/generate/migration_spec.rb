# frozen_string_literal: true

require "hanami"

RSpec.describe Hanami::CLI::Commands::App::Generate::Migration, :app do
  subject { described_class.new(fs: fs, inflector: inflector, err: err) }

  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  def output
    out.string.strip
  end

  def error_output = err.string.chomp

  let(:app) { Hanami.app.namespace }

  let(:migration_file_contents) {
    <<~RUBY
      # frozen_string_literal: true

      ROM::SQL.migration do
        # Add your migration here.
        #
        # See https://guides.hanamirb.org/v2.2/database/migrations/ for details.
        change do
        end
      end
    RUBY
  }

  before do
    allow(Time).to receive(:now) { Time.new(2024, 7, 13, 14, 6, 0) }
  end

  context "generating for app" do
    it "generates a migration" do
      subject.call(name: "create_posts")

      expect(fs.read("config/db/migrate/20240713140600_create_posts.rb")).to eq migration_file_contents
      expect(output).to eq("Created config/db/migrate/20240713140600_create_posts.rb")
    end

    it "generates a migration for a gateway" do
      subject.call(name: "create_posts", gateway: "extra")

      expect(fs.read("config/db/extra_migrate/20240713140600_create_posts.rb")).to eq migration_file_contents
      expect(output).to eq("Created config/db/extra_migrate/20240713140600_create_posts.rb")
    end

    it "generates a migration with underscored version of camel cased name" do
      subject.call(name: "CreatePosts")

      expect(fs.read("config/db/migrate/20240713140600_create_posts.rb")).to eq migration_file_contents
      expect(output).to eq("Created config/db/migrate/20240713140600_create_posts.rb")
    end

    it "raises an error if given an invalid name" do
      expect {
        subject.call(name: "create posts")
      }.to raise_error(include_in_order(
                         "Invalid migration name: create posts",
                         "Name must contain only letters, numbers, and underscores."
                       ))
    end

    context "with existing file" do
      let(:file_path) { "config/db/migrate/20240713140600_create_posts.rb" }

      before do
        fs.write(file_path, "existing content")
      end

      it "exits with error message" do
        expect do
          subject.call(name: "create_posts")
        end.to raise_error SystemExit do |exception|
          expect(exception.status).to eq 1
          expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
        end
      end
    end
  end

  context "generating for a slice" do
    it "generates a migration" do
      fs.mkdir("slices/main")
      out.truncate 0

      subject.call(name: "create_posts", slice: "main")

      expect(fs.read("slices/main/config/db/migrate/20240713140600_create_posts.rb")).to eq migration_file_contents
      expect(output).to eq("Created slices/main/config/db/migrate/20240713140600_create_posts.rb")
    end

    context "with existing file" do
      let(:file_path) { "slices/main/config/db/migrate/20240713140600_create_posts.rb" }

      context "with existing file" do
        before do
          fs.write(file_path, "existing content")
        end

        it "exits with error message" do
          expect do
            subject.call(name: "create_posts", slice: "main")
          end.to raise_error SystemExit do |exception|
            expect(exception.status).to eq 1
            expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
          end
        end
      end
    end
  end
end
