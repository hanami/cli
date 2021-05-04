# frozen_string_literal: true

# FIXME: require "hanami/application" should work but it fails
#       due to missing Hanami.env
require "hanami"

module Test
  class Application < Hanami::Application
    config.root = Pathname(__dir__).join("..").realpath
  end
end
