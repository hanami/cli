# frozen_string_literal: true

RSpec.describe Hanami::CLI::Generators::Version do
  describe ".version" do
    context "when Hanami::VERSION is defined" do
      it "returns Hanami::VERSION" do
        stub_const("Hanami::VERSION", "2.0.0")
        expect(described_class.version).to eq("2.0.0")
      end
    end

    context "when Hanami::VERSION is NOT defined" do
      before do
        allow(Hanami).to receive(:const_defined?).with(:VERSION).and_return(false)
      end

      xit "returns Hanami::CLI::VERSION" do
        stub_const("Hanami::CLI::VERSION", "2.0.1")
        expect(described_class.version).to eq("2.0.1")
      end
    end
  end

  describe ".gem_requirement" do
    context "when prerelease version" do
      before do
        allow(described_class).to receive(:prerelease?).and_return(true)
        allow(described_class).to receive(:prerelease_version).and_return("2.0.0.alpha")
      end

      it "returns the prerelease version requirement" do
        expect(described_class.gem_requirement).to eq("~> 2.0.0.alpha")
      end
    end

    context "when stable version" do
      before do
        allow(described_class).to receive(:prerelease?).and_return(false)
        allow(described_class).to receive(:stable_version).and_return("2.0")
      end

      it "returns the stable version requirement" do
        expect(described_class.gem_requirement).to eq("~> 2.0")
      end
    end
  end

  describe ".npm_package_requirement" do
    context "when prerelease version" do
      it "formats the alpha version string for npm" do
        allow(described_class).to receive(:version).and_return("2.1.0.alpha8.1")
        expect(described_class.npm_package_requirement).to eq("^2.1.0-alpha.8")
      end

      it "formats the beta version string for npm" do
        allow(described_class).to receive(:version).and_return("2.1.0.beta2")
        expect(described_class.npm_package_requirement).to eq("^2.1.0-beta.2")
      end

      it "formats the rc version string for npm" do
        allow(described_class).to receive(:version).and_return("2.1.0.rc1")
        expect(described_class.npm_package_requirement).to eq("^2.1.0-rc.1")
      end
    end

    context "when stable version" do
      it "formats the stable version string for npm" do
        allow(described_class).to receive(:version).and_return("2.1.0")
        expect(described_class.npm_package_requirement).to eq("^2.1.0")
      end

      it "formats the stable version string (with tiny patch) for npm" do
        allow(described_class).to receive(:version).and_return("2.1.0.1")
        expect(described_class.npm_package_requirement).to eq("^2.1.0.1")
      end
    end
  end

  describe ".prerelease?" do
    it "returns true for prerelease version" do
      allow(described_class).to receive(:version).and_return("2.1.0.beta2.1")
      expect(described_class.prerelease?).to be true
    end

    it "returns false for stable version" do
      allow(described_class).to receive(:version).and_return("2.1.0")
      expect(described_class.prerelease?).to be false
    end
  end

  describe ".stable_version" do
    it "returns the major and minor version" do
      allow(described_class).to receive(:version).and_return("2.1.0")
      expect(described_class.stable_version).to eq("2.1")
    end
  end

  describe ".prerelease_version" do
    it "returns the version without the last digit group" do
      allow(described_class).to receive(:version).and_return("2.0.0.alpha8.1")
      expect(described_class.prerelease_version).to eq("2.0.0.alpha")
    end
  end
end
