# frozen_string_literal: true

require "hanami/cli"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # config.before :suite do
  #   require "hanami/devtools/integration"
  #   Pathname.new(Dir.pwd).join("tmp").mkpath
  # end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = false

  config.default_formatter = "doc" if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  RSpec.shared_context "app" do
    let(:app) do
      Test::App
    end
  end

  RSpec.shared_context "command" do
    subject(:command) { described_class.new(out: out) }

    let(:out) { StringIO.new }

    let(:output) {
      out.rewind
      out.read
    }
  end

  RSpec.shared_context "database" do
    let(:database) do
      instance_double(Hanami::CLI::Commands::App::DB::Utils::Database, name: "test")
    end

    before do
      allow(command).to receive(:database).and_return(database)
    end
  end

  config.include_context("command", command: true)
  config.include_context("database", db: true)
  config.include_context("app", app: true)

  config.around(app: true) do |example|
    require_relative "fixtures/test/config/app" unless defined?(Test::App)
    example.run
  end
end

Dir.glob("#{__dir__}/support/**/*.rb").each(&method(:require))
