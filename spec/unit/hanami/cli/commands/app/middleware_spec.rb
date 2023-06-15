# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Middleware, :app, :command do
  # TODO: better Hanami tear down
  after do
    app = Hanami.app
    app.remove_instance_variable(:@_router) if app.instance_variable_defined?(:@_router)
  end

  it "lists registered middleware" do
    command.call

    expect(output).to eq <<~OUTPUT
      /    Dry::Monitor::Rack::Middleware (instance)
      /    Hanami::Middleware::RenderErrors
    OUTPUT
  end

  it "can include arguments" do
    command.call(with_arguments: true)

    expect(output).to include("args: []")
  end

  context "no router" do
    before do
      allow(Hanami.app).to receive(:router).and_return nil
    end

    it "outputs nothing" do
      command.call

      expect(output).to be_empty
    end
  end
end
