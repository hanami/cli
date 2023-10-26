# frozen_string_literal: true

require "dry/inflector"

RSpec.describe Hanami::CLI::Generators::Context do
  subject { described_class.new(inflector, app) }

  let(:inflector) { Dry::Inflector.new }
  let(:app) { double("app") }

  describe "#ruby_omit_hash_values?" do
    if RUBY_VERSION >= "3.1"
      it "returns true" do
        expect(subject.ruby_omit_hash_values?).to be(true)
      end
    else
      it "returns false" do
        expect(subject.ruby_omit_hash_values?).to be(false)
      end
    end
  end
end
