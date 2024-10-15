# frozen_string_literal: true

RSpec.describe "Hanami::CLI::VERSION" do
  it "returns version" do
    expect(Hanami::CLI::VERSION).to eq("2.2.0.beta2")
  end
end
