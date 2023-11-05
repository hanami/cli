# frozen_string_literal: true

RSpec.describe Hanami::CLI::Generators::Version do
  describe "#npm_package_requirement" do
    it "returns the npm package version" do
      allow(Hanami::CLI::Generators::Version).to receive(:version).and_return("2.1.0.rc1")

      expect(subject.npm_package_requirement).to eq("^2.1.0-rc.1")

      allow(Hanami::CLI::Generators::Version).to receive(:version).and_return("2.1.0.rc1.1")

      expect(subject.npm_package_requirement).to eq("^2.1.0-rc.1")
    end
  end
end
