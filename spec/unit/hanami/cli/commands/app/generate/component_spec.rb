# frozen_string_literal: true

require "hanami"
require "ostruct"

RSpec.describe Hanami::CLI::Commands::App::Generate::Component, :app do
  subject { described_class.new(fs: fs, out: out) }

  let(:out) { StringIO.new }
  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { Hanami.app.namespace }
  let(:underscored_app) { inflector.underscore(app) }
  let(:dir) { underscored_app }
  let(:slice) { "api" }

  def output
    out.rewind && out.read.chomp
  end

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
end
