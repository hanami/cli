# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", require: false, platforms: :mri
  gem "yard",   require: false
end

gem "hanami", require: false, git: "https://github.com/hanami/hanami.git", branch: "unstable"
gem "hanami-view", require: false, git: "https://github.com/hanami/view.git", branch: "unstable"

gem "rack"

group :test do
  gem "pry"
end
