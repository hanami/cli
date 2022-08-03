# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", require: false, platforms: :mri
  gem "yard",   require: false
end

gem "dry-files", require: false, github: "dry-rb/dry-files", branch: "inject_line_at_block_bottom-nested-block-2"
gem "hanami", require: false, github: "hanami/hanami", branch: :main
gem "hanami-router", github: "hanami/router", branch: :main

gem "rack"

group :test do
  gem "pry"
end
