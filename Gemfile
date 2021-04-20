# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", require: false, platforms: :mri
  gem "yard",   require: false
end

gem "dry-files", "~> 0.1", require: false, git: "https://github.com/dry-rb/dry-files.git", branch: "master"
gem "hanami", require: false, git: "https://github.com/hanami/hanami.git", branch: "feature/hanami-2-cli"
gem "rack"
