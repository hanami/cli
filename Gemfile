# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", platforms: :mri
  gem "yard"
  gem "yard-junk"
end

gem "hanami", github: "hanami/hanami", branch: "main"
gem "hanami-assets", github: "hanami/assets", branch: "main"
gem "hanami-controller", github: "hanami/controller", branch: "main"
gem "hanami-db", github: "hanami/db", branch: "main"
gem "hanami-router", github: "hanami/router", branch: "main"
gem "hanami-utils", github: "hanami/utils", branch: "main"

gem "dry-files", github: "dry-rb/dry-files", branch: "main"
gem "dry-cli", github: "dry-rb/dry-cli", branch: "main"

gem "rack"

gem "pg"
gem "sqlite3"

gem "hanami-devtools", github: "hanami/devtools", branch: "main"

group :test do
  gem "pry"
end
