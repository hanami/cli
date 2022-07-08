# frozen_string_literal: true

require "hanami/routes"

module Test
  class Routes < Hanami::Routes
    define do
      get "/", to: "home.index"
      get "/about", to: "home.about"
    end
  end
end
