# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", require: false, platforms: :mri
  gem "yard",   require: false
end

gem "dry-system", "~> 1.0.0.rc1"

gem "hanami", github: "hanami/hanami", branch: "main"
gem "hanami-router", github: "hanami/router", branch: "main"
gem "hanami-controller", github: "hanami/controller", branch: "main"

gem "rack"

group :test do
  gem "pry"
end
