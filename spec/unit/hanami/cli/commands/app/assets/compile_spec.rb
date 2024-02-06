# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Assets::Compile, "#call", :app_integration do
  subject(:compile_command) {
    described_class.new(
      system_call: interactive_system_call,
      out: out
    )
  }

  let(:interactive_system_call) { instance_double(Hanami::CLI::InteractiveSystemCall) }

  let(:out) { StringIO.new }
  let(:output) {
    out.rewind
    out.read
  }

  before do
    with_directory(make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/assets.js", ""

      require "hanami/setup"
      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  before do
    # Instead of forking a process per slice, run that code directly. This is is necessary becuase
    # RSpec method expectations won't work on objects in a forked process.
    allow(Process).to receive(:fork).and_wrap_original do |_original_method, &block|
      block.call
    end
  end

  describe "assets in app" do
    describe "assets dir present" do
      def before_prepare
        write "assets/.keep", ""
      end

      it "compiles the app assets" do
        expect(interactive_system_call).to receive(:call).with(
          "node",
          Hanami.app.root.join("config", "assets.js").to_s,
          "--",
          "--path=app",
          "--dest=public/assets",
          {out_prefix: "[test_app] "}
        )

        compile_command.call
      end
    end

    describe "assets dir absent" do
      it "does not watch app assets" do
        expect(interactive_system_call).not_to receive(:call)

        compile_command.call

        expect(output).to eq "No assets found.\n"
      end
    end
  end

  describe "assets in slice" do
    describe "assets dir present" do
      def before_prepare
        write "slices/admin/assets/.keep", ""
      end

      it "compiles the slice assets" do
        expect(interactive_system_call).to receive(:call).with(
          "node",
          Hanami.app.root.join("config", "assets.js").to_s,
          "--",
          "--path=slices/admin",
          "--dest=public/assets/admin",
          {out_prefix: "[admin] "}
        )

        compile_command.call
      end
    end

    describe "slice assets config file" do
      def before_prepare
        write "slices/admin/config/assets.js", ""
        write "slices/admin/assets/.keep", ""
      end

      it "compiles the slice assets using the slice's assets config" do
        expect(interactive_system_call).to receive(:call).with(
          "node",
          Hanami.app.root.join("slices", "admin", "config", "assets.js").to_s,
          "--",
          "--path=slices/admin",
          "--dest=public/assets/admin",
          {out_prefix: "[admin] "}
        )

        compile_command.call
      end
    end

    describe "assets dir absent" do
      def before_prepare
        write "slices/admin/.keep", ""
      end

      it "does not watch app assets" do
        expect(interactive_system_call).not_to receive(:call)

        compile_command.call
      end
    end
  end

  describe "assets present in multiple slices" do
    def before_prepare
      write "slices/admin/assets/.keep", ""
      write "slices/main/assets/.keep", ""
    end

    it "compiles the assets for each slice" do
      expect(interactive_system_call).to receive(:call).with(
        "node",
        Hanami.app.root.join("config", "assets.js").to_s,
        "--",
        "--path=slices/admin",
        "--dest=public/assets/admin",
        {out_prefix: "[admin] "}
      )

      expect(interactive_system_call).to receive(:call).with(
        "node",
        Hanami.app.root.join("config", "assets.js").to_s,
        "--",
        "--path=slices/main",
        "--dest=public/assets/main",
        {out_prefix: "[main] "}
      )

      compile_command.call
    end
  end

  describe "subresource integrity configured" do
    def before_prepare
      Hanami.app.config.assets.subresource_integrity = [:sha256, :sha512]
      write "assets/.keep", ""
    end

    it "passes the setting via the --sri flag" do
      expect(interactive_system_call).to receive(:call).with(
        "node",
        Hanami.app.root.join("config", "assets.js").to_s,
        "--",
        "--path=app",
        "--dest=public/assets",
        "--sri=sha256,sha512",
        {out_prefix: "[test_app] "}
      )

      compile_command.call
    end
  end
end
