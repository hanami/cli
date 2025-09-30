# frozen_string_literal: true

require "hanami"
require "ostruct"

RSpec.describe Hanami::CLI::Commands::App::Generate::Component, :app do
  subject { described_class.new(fs: fs, out: out, err: err) }

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { Hanami.app.namespace }
  let(:underscored_app) { inflector.underscore(app) }
  let(:dir) { underscored_app }
  let(:slice) { "api" }

  def output
    out.rewind && out.read.chomp
  end

  def error_output = err.string.chomp

  context "generating for app" do
    context "shallowly nested" do
      it "generates the component" do
        subject.call(name: "operations.send_welcome_email")

        component = <<~EXPECTED
          # frozen_string_literal: true

          module Test
            module Operations
              class SendWelcomeEmail
              end
            end
          end
        EXPECTED

        expect(fs.read("app/operations/send_welcome_email.rb")).to eq(component)
        expect(output).to include("Created app/operations/send_welcome_email.rb")
      end

      context "with existing file" do
        let(:file_path) { "app/operations/send_welcome_email.rb" }

        before do
          fs.write(file_path, "existing content")
        end

        it "exits with error message" do
          expect do
            subject.call(name: "operations.send_welcome_email")
          end.to raise_error SystemExit do |exception|
            expect(exception.status).to eq 1
            expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
          end
        end
      end
    end

    context "deeply nested" do
      it "generates the component" do
        subject.call(name: "operations.user.mailing.send_welcome_email")

        component = <<~EXPECTED
          # frozen_string_literal: true

          module Test
            module Operations
              module User
                module Mailing
                  class SendWelcomeEmail
                  end
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("app/operations/user/mailing/send_welcome_email.rb")).to eq(component)
        expect(output).to include("Created app/operations/user/mailing/send_welcome_email.rb")
      end

      context "with existing file" do
        let(:file_path) { "app/operations/user/mailing/send_welcome_email.rb" }

        before do
          fs.write(file_path, "existing content")
        end

        it "exits with error message" do
          expect do
            subject.call(name: "operations.user.mailing.send_welcome_email")
          end.to raise_error SystemExit do |exception|
            expect(exception.status).to eq 1
            expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
          end
        end
      end
    end
  end

  context "generating for a slice" do
    context "shallowly nested" do
      it "generates the component" do
        fs.mkdir("slices/main")
        subject.call(name: "renderers.welcome_email", slice: "main")

        component = <<~EXPECTED
          # frozen_string_literal: true

          module Main
            module Renderers
              class WelcomeEmail
              end
            end
          end
        EXPECTED

        expect(fs.read("slices/main/renderers/welcome_email.rb")).to eq(component)
        expect(output).to include("Created slices/main/renderers/welcome_email.rb")
      end

      context "with existing file" do
        let(:file_path) { "slices/main/renderers/welcome_email.rb" }

        before do
          fs.write(file_path, "existing content")
        end

        it "exits with error message" do
          expect do
            subject.call(name: "renderers.welcome_email", slice: "main")
          end.to raise_error SystemExit do |exception|
            expect(exception.status).to eq 1
            expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
          end
        end
      end
    end

    context "deeply nested" do
      it "generates the component" do
        fs.mkdir("slices/main")
        subject.call(name: "renderers.user.mailing.welcome_email", slice: "main")

        component = <<~EXPECTED
          # frozen_string_literal: true

          module Main
            module Renderers
              module User
                module Mailing
                  class WelcomeEmail
                  end
                end
              end
            end
          end
        EXPECTED

        expect(fs.read("slices/main/renderers/user/mailing/welcome_email.rb")).to eq(component)
        expect(output).to include("Created slices/main/renderers/user/mailing/welcome_email.rb")
      end

      context "with existing file" do
        let(:file_path) { "slices/main/renderers/user/mailing/welcome_email.rb" }

        before do
          fs.write(file_path, "existing content")
        end

        it "exits with error message" do
          expect do
            subject.call(name: "renderers.user.mailing.welcome_email", slice: "main")
          end.to raise_error SystemExit do |exception|
            expect(exception.status).to eq 1
            expect(error_output).to eq Hanami::CLI::FileAlreadyExistsError::ERROR_MESSAGE % {file_path:}
          end
        end
      end
    end

    context "with missing slice" do
      it "raises error" do
        expect { subject.call(name: "user", slice: "foo") }.to raise_error(Hanami::CLI::MissingSliceError)
      end
    end
  end

  context "with namespaced constant name for component given" do
    it "generates the component" do
      subject.call(name: "Operations::SendWelcomeEmail")

      component = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          module Operations
            class SendWelcomeEmail
            end
          end
        end
      EXPECTED

      expect(fs.read("app/operations/send_welcome_email.rb")).to eq(component)
      expect(output).to include("Created app/operations/send_welcome_email.rb")
    end
  end

  context "with capitalized component name" do
    it "generates the component with downcased filename" do
      subject.call(name: "Entry")

      component = <<~EXPECTED
        # frozen_string_literal: true

        module Test
          class Entry
          end
        end
      EXPECTED

      expect(fs.read("app/entry.rb")).to eq(component)
      expect(output).to include("Created app/entry.rb")
    end

    context "when nested" do
      it "generates the component with downcased filename" do
        subject.call(name: "operations.Entry")

        component = <<~EXPECTED
          # frozen_string_literal: true

          module Test
            module Operations
              class Entry
              end
            end
          end
        EXPECTED

        expect(fs.read("app/operations/entry.rb")).to eq(component)
        expect(output).to include("Created app/operations/entry.rb")
      end
    end

    context "when using constant syntax" do
      it "generates the component with downcased filename" do
        subject.call(name: "Operations::Entry")

        component = <<~EXPECTED
          # frozen_string_literal: true

          module Test
            module Operations
              class Entry
              end
            end
          end
        EXPECTED

        expect(fs.read("app/operations/entry.rb")).to eq(component)
        expect(output).to include("Created app/operations/entry.rb")
      end
    end
  end
end
