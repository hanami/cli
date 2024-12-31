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
gem "hanami-controller", github: "kyleplump/controller", branch: "rack3"
gem "hanami-db", github: "hanami/db", branch: "main"
gem "hanami-router", github: "kyleplump/router", branch: "rack3"
gem "hanami-utils"

gem "dry-system", github: "dry-rb/dry-system", branch: "main"

gem "rack", "~> 3.1"

gem "mysql2"
gem "pg"
gem "sqlite3"

gem "hanami-devtools", github: "kyleplump/devtools", branch: "rack3"

group :test do
  gem "pry"
end
