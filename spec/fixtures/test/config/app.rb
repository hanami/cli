# FIXME: require "hanami/app" should work but it fails
#       due to missing Hanami.env
require "hanami"

module Test
  class App < Hanami::App
    config.root = Pathname(__dir__).join("..").realpath
  end
end
