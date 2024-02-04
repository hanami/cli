# frozen_string_literal: true

source "https://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", platforms: :mri
  gem "yard"
  gem "yard-junk"
end

gem "hanami", github: "hanami/hanami", branch: "main"
gem "hanami-assets", github: "hanami/assets", branch: "change-package-manager-setting"
gem "hanami-controller", github: "hanami/controller", branch: "main"
gem "hanami-router", github: "hanami/router", branch: "main"
gem "hanami-utils", github: "hanami/utils", branch: "main"

gem "dry-files", github: "dry-rb/dry-files", branch: "main"

gem "rack"

gem "hanami-devtools", github: "hanami/devtools", branch: "main"

group :test do
  gem "pry"
end
