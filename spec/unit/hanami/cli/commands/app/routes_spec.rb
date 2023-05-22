RSpec.describe Hanami::CLI::Commands::App::Routes, :app, :command do # see fixture app for the defined routes
  # TODO: better Hanami tear down
  after do
    app = Hanami.app
    app.remove_instance_variable(:@_router) if app.instance_variable_defined?(:@_router)
  end

  it "defaults to the human friendly formatter" do
    command.call

    expect(output).to match %r{
     ^GET\s+/\s+home\.index.*
      GET\s+/about\s+home\.about\s+$
    }xm
  end

  it "can use the csv formatter" do
    command.call(format: "csv")

    expect(output).to match %r{
      GET,/,home\.index.*
      GET,/about,home\.about
    }xm
  end

  it "can use a custom formatter registered in the container" do
    formatter = ->(routes) do
      routes.filter_map { |route| !route.head? && route.http_method }.join(" ")
    end
    app.register_provider :custom_routes_formatter do
      start { register "custom_routes_formatter", formatter }
    end

    command.call(format: "custom_routes_formatter")

    expect(output).to match %r{GET GET}
  end
end
