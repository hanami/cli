# frozen_string_literal: true

require "hanami/routes"

module Test
  class Routes < Hanami::Routes
    get "/", to: "home.index"
    get "/about", to: "home.about"
  end
end
