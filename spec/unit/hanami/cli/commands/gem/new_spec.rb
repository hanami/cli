# frozen_string_literal: true

require "hanami/cli/commands/gem/new"
require "ostruct"

RSpec.describe Hanami::CLI::Commands::Gem::New do
  subject { described_class.new(bundler: bundler, command_line: command_line, out: stdout, fs: fs) }

  let(:bundler) { Hanami::CLI::Bundler.new(fs: fs) }
  let(:command_line) { Hanami::CLI::CommandLine.new(bundler: bundler) }
  let(:stdout) { StringIO.new }
  let(:fs) { Dry::CLI::Utils::Files.new(memory: true) }
  let(:app) { "bookshelf" }

  it "normalizes app name" do
    expect(bundler).to receive(:install!)
      .and_return(true)

    expect(command_line).to receive(:call)
      .with("hanami install")
      .and_return(OpenStruct.new(successful?: true))

    expect(command_line).to receive(:call)
      .with("hanami generate slice main")
      .and_return(OpenStruct.new(successful?: true))

    app_name = "PropagandaLive"
    app = "propaganda_live"
    subject.call(app: app_name)

    expect(fs.directory?(app)).to be(true)
  end

  context "architecture: unknown" do
    let(:architecture) { "unknown" }

    it "raises error" do
      expect do
        subject.call(app: app, architecture: architecture)
      end.to raise_error(ArgumentError, "unknown architecture `#{architecture}'")
    end
  end
end
