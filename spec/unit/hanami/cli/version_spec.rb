RSpec.describe "Hanami::CLI::VERSION" do
  it "returns version" do
    expect(Hanami::CLI::VERSION).to eq("2.0.3")
  end
end
