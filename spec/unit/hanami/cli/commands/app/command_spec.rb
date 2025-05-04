# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Command, :app do
  context "#call" do
    subject { cmd.new }

    let(:cmd) do
      Class.new(described_class) do
        def call(**)
        end
      end
    end

    it "invokes Hanami::Env.load" do
      expect(Hanami::Env).to receive(:load)

      subject.call
    end
  end

  context "#detect_slice_from_pwd" do
    let(:out) { StringIO.new }
    let(:fs) { Hanami::CLI::Files.new(memory: true, out: out) }
    let(:inflector) { Dry::Inflector.new }
    let(:slice_registrar) { instance_double(Hanami::SliceRegistrar) }

    context "for all commands" do
      %w[View Struct Repo Operation Component Action Part Migration Relation].each do |cmd|
        it "doesn't crash when slice does not exist" do
          allow(app).to receive(:root).and_return(Pathname.new("some_folder/my_app/"))
          allow(slice_registrar).to receive(:load_slices).and_return([])
          allow(slice_registrar).to receive(:keys).and_return([])
          allow(app).to receive(:slices).and_return(slice_registrar)
          allow(Pathname).to receive(:pwd).and_return(Pathname.new("some_folder/my_app/lib"))

          command = Object.const_get("Hanami::CLI::Commands::App::Generate::#{cmd}").new(fs: fs, inflector: inflector)

          expect(command.detect_slice_from_pwd).to eq(nil)
        end

        it "works for all commands" do
          fs.mkdir("slices/admin")
          allow(app).to receive(:root).and_return(Pathname.new("some_folder/my_app/"))
          allow(slice_registrar).to receive(:load_slices).and_return([])
          allow(slice_registrar).to receive(:keys).and_return([:admin])
          allow(slice_registrar).to receive(:[]).with(:admin).and_return(:mocked_value)
          allow(app).to receive(:slices).and_return(slice_registrar)
          allow(Pathname).to receive(:pwd).and_return(Pathname.new("some_folder/my_app/slices/admin"))

          command = Object.const_get("Hanami::CLI::Commands::App::Generate::#{cmd}").new(fs: fs, inflector: inflector)

          expect(command.detect_slice_from_pwd).to eq("admin")
        end
      end
    end
  end
end
