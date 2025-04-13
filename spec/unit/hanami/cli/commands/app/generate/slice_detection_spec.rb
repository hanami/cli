# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Generate::SliceDetection do
  subject(:command) { command_class.new(fs: fs, inflector: inflector) }

  let(:command_class) do
    Class.new(Hanami::CLI::Commands::App::Command) do
      include Hanami::CLI::Commands::App::Generate::SliceDetection
    end
  end

  let(:fs) { instance_double("Dry::Files") }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { instance_double("Hanami::App", root: root, slices: slices) }
  let(:root) { Pathname.new("/path/to/app") }
  let(:slices) { { "admin" => admin_slice } }
  let(:admin_slice) { instance_double("Hanami::Slice") }

  before do
    allow(command).to receive(:app).and_return(app)
  end

  describe "#detect_slice_from_current_directory" do
    subject { command.send(:detect_slice_from_current_directory) }

    context "when in the app root directory" do
      before do
        allow(Dir).to receive(:pwd).and_return("/path/to/app")
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when in the app directory" do
      before do
        allow(Dir).to receive(:pwd).and_return("/path/to/app/app")
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when in a slice directory" do
      before do
        allow(Dir).to receive(:pwd).and_return("/path/to/app/slices/admin")
      end

      it "returns the slice name" do
        expect(subject).to eq("admin")
      end
    end

    context "when in a subdirectory of a slice" do
      before do
        allow(Dir).to receive(:pwd).and_return("/path/to/app/slices/admin/actions")
      end

      it "returns the slice name" do
        expect(subject).to eq("admin")
      end
    end

    context "when in a non-existent slice directory" do
      before do
        allow(Dir).to receive(:pwd).and_return("/path/to/app/slices/nonexistent")
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when in an unrelated directory" do
      before do
        allow(Dir).to receive(:pwd).and_return("/some/other/path")
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end
end
