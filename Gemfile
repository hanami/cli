# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", platforms: :mri
  gem "yard"
  gem "yard-junk"
end

gem "dry-system", "~> 1.0.0.rc1"

gem "hanami", github: "hanami/hanami", branch: "main"
gem "hanami-utils", github: "hanami/utils", branch: "main"
gem "hanami-router", github: "hanami/router", branch: "main"
gem "hanami-controller", github: "hanami/controller", branch: "main"

gem "rack"

group :test do
  gem "pry"
end
