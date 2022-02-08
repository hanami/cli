# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", require: false, platforms: :mri
  gem "yard",   require: false
end

gem "dry-system", require: false, git: "https://github.com/dry-rb/dry-system.git", branch: "master"

gem "hanami", require: false, git: "https://github.com/hanami/hanami.git", branch: "main"
gem "hanami-router", require: false, git: "https://github.com/hanami/router.git", branch: "main"
gem "hanami-view", require: false, git: "https://github.com/hanami/view.git", branch: "main"

gem "rack"

group :test do
  gem "pry"
end
