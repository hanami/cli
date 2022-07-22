# frozen_string_literal: true

require "hanami/cli/commands/app/middlewares"

RSpec.describe Hanami::CLI::Commands::App::Middlewares, :app, :command do
  # TODO: better Hanami tear down
  after do
    app = Hanami.app
    app.remove_instance_variable(:@_router) if app.instance_variable_defined?(:@_router)
  end

  it "lists registered middlewares" do
    command.call

    expect(output).to eq <<~OUTPUT
      /    Dry::Monitor::Rack::Middleware (instance)
    OUTPUT
  end

  it "can include arguments" do
    command.call(with_arguments: true)

    expect(output).to include("args: []")
  end
end
