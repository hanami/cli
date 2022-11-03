# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", require: false, platforms: :mri
  gem "yard",   require: false
end

gem "dry-auto_inject", github: "dry-rb/dry-auto_inject"
gem "dry-configurable", github: "dry-rb/dry-configurable"
gem "dry-core", github: "dry-rb/dry-core"
gem "dry-events", github: "dry-rb/dry-events"
gem "dry-inflector", github: "dry-rb/dry-inflector"
gem "dry-logic", github: "dry-rb/dry-logic"
gem "dry-monitor", github: "dry-rb/dry-monitor"
gem "dry-system", github: "dry-rb/dry-system"
gem "dry-types", github: "dry-rb/dry-types"

gem "hanami", require: false, github: "hanami/hanami", branch: :main
gem "hanami-router", github: "hanami/router", branch: :main

gem "rack"

group :test do
  gem "pry"
end
