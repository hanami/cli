require "hanami"

app = ->(_env) { [200, {}, ["Hello, world! (#{Hanami.env})"]] }

run app
