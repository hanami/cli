# frozen_string_literal: true

RSpec.describe Hanami::CLI::SliceDetection do
  subject(:command) do
    command_class.new(
      fs: instance_double("Dry::Files"),
      inflector: Dry::Inflector.new,
      out: StringIO.new,
      err: StringIO.new
    )
  end

  let(:command_class) do
    Class.new(Hanami::CLI::Commands::App::Command) do
      include Hanami::CLI::SliceDetection
    end
  end

  let(:app) do
    instance_double(
      "Hanami::App",
      root: Pathname.new("/home/user/code/hanami_app"),
      slices: {admin: instance_double("Hanami::Slice")}
    )
  end

  before do
    allow(command).to receive(:app).and_return(app)
  end

  describe "#detect_slice_from_current_directory" do
    subject { command.send(:detect_slice_from_current_directory) }

    context "when in the app root directory" do
      before do
        allow(Dir).to receive(:pwd).and_return("/home/user/code/hanami_app")
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when in the app directory" do
      before do
        allow(Dir).to receive(:pwd).and_return("/home/user/code/hanami_app")
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when in a slice directory" do
      before do
        allow(Dir).to receive(:pwd).and_return("/home/user/code/hanami_app/slices/admin")
      end

      it "returns the slice name" do
        expect(subject).to eq("admin")
      end
    end

    context "when in a subdirectory of a slice" do
      before do
        allow(Dir).to receive(:pwd).and_return("/home/user/code/hanami_app/slices/admin/actions")
      end

      it "returns the slice name" do
        expect(subject).to eq("admin")
      end
    end

    context "when in a non-existent slice directory" do
      before do
        allow(Dir).to receive(:pwd).and_return("/home/user/code/hanami_app/slices/nonexistent")
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
