# frozen_string_literal: true

require "hanami"

module Test
  class App < Hanami::App
    config.root = Pathname(__dir__).join("..").realpath
    config.console.engine = :irb
  end
end
