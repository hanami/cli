# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Routes, :app_integration do
  subject(:command) { described_class.new(out: out) }

  let(:out) { StringIO.new }
  let(:output) {
    out.rewind
    out.read
  }

  before do
    with_directory(@dir = make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "config/routes.rb", <<~RUBY
        require "hanami/routes"

        module TestApp
          class Routes < Hanami::Routes
            get "/", to: "home.index"
            get "/about", to: "home.about"
          end
        end
      RUBY

      require "hanami/setup"
      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
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

  context "custom formatter registered" do
    before do
      formatter = ->(routes) do
        routes.filter_map { |route| !route.head? && route.http_method }.join(" ")
      end

      Hanami.app.register_provider :custom_routes_formatter do
        start { register "custom_routes_formatter", formatter }
      end
    end

    it "can use a custom formatter registered in the container" do
      command.call(format: "custom_routes_formatter")

      expect(output).to match %r{GET GET}
    end
  end
end
