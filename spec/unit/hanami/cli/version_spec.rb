# frozen_string_literal: true

RSpec.describe "Hanami::CLI::VERSION" do
  it "returns version" do
    expect(Hanami::CLI::VERSION).to eq("2.0.0.beta3")
  end
end
