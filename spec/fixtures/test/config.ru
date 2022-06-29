# frozen_string_literal: true

require "hanami"

app = ->(_env) { [200, {}, ["Hello, world! (#{Hanami.env})"]] }

run app
