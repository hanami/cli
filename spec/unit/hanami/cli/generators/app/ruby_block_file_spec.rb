# frozen_string_literal: true

RSpec.describe Hanami::CLI::Generators::App::RubyBlockFile do
  subject { described_class.new(**args) }

  let(:fs) { instance_double(Hanami::CLI::Files) }
  let(:inflector) { Dry::Inflector.new }
  let(:key) { "test_config" }
  let(:namespace) { nil }
  let(:extra_namespace) { nil }
  let(:base_path) { "config" }
  let(:body) { ["puts 'hello'", "puts 'world'"] }
  let(:signature) { "configure" }

  let(:args) do
    {
      fs:,
      inflector:,
      key:,
      namespace:,
      extra_namespace:,
      base_path:,
      signature:,
      body:,
    }
  end

  describe "#generate" do
    describe "without signature" do
      let(:signature) { nil }

      it "raises ArgumentError " do
        expect { subject.contents }.to raise_error(ArgumentError).with_message(
          "`signature` is required"
        )
      end
    end

    context "with signature including arguments" do
      let(:signature) { "configure env, settings" }

      it "includes the arguments in the block definition" do
        expect(subject.contents).to include("configure env, settings do")
      end
    end

    describe "with namespace" do
      let(:namespace) { "test_app" }

      it "generates a block structure inside namespace" do
        expect(subject.contents).to eq(
          <<~FILE
            # frozen_string_literal: true

            module TestApp
              configure do
                puts 'hello'
                puts 'world'
              end
            end
          FILE
        )
      end
    end

    describe "with extra_namespace" do
      let(:extra_namespace) { "app_config" }

      it "generates a block structure inside namespace" do
        expect(subject.contents).to eq(
          <<~FILE
            # frozen_string_literal: true

            module AppConfig
              configure do
                puts 'hello'
                puts 'world'
              end
            end
          FILE
        )
      end
    end

    describe "with namespace and extra_namespace" do
      let(:namespace) { "test_app" }
      let(:extra_namespace) { "app_config" }

      it "generates a block structure inside namespace" do
        expect(subject.contents).to eq(
          <<~FILE
            # frozen_string_literal: true

            module TestApp
              module AppConfig
                configure do
                  puts 'hello'
                  puts 'world'
                end
              end
            end
          FILE
        )
      end
    end

    context "with empty body" do
      let(:body) { [] }

      it "generates an empty block" do
        expect(subject.contents).to eq(
          <<~FILE
            # frozen_string_literal: true

            configure do
            end
          FILE
        )
      end
    end

    context "with body including empty lines, inside namespace" do
      let(:body) { ["puts 'start'", "", "puts 'stop'"] }
      let(:namespace) { "test_app" }

      it "properly indents content and preserves empty lines" do
        expect(subject.contents).to eq(
          <<~FILE
            # frozen_string_literal: true

            module TestApp
              configure do
                puts 'start'

                puts 'stop'
              end
            end
          FILE
        )
      end
    end
  end

  describe "#create" do
    let(:signature) { "configure" }

    it "delegates to RubyFile#create" do
      allow(fs).to receive(:create)
      allow(subject).to receive(:path).and_return("test/path.rb")
      allow(subject).to receive(:contents).and_return("generated code")

      subject.create

      expect(fs).to have_received(:create).with("test/path.rb", /generated code/)
    end
  end

  describe "#write" do
    let(:signature) { "configure" }

    it "delegates to RubyFile#write" do
      allow(fs).to receive(:write)
      allow(subject).to receive(:path).and_return("test/path.rb")
      allow(subject).to receive(:contents).and_return("generated code")

      subject.write

      expect(fs).to have_received(:write).with("test/path.rb", /generated code/)
    end
  end
end
