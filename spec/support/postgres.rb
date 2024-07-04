# frozen_string_literal: true

require "open3"
require "uri"

# Default to a URL that should work with postgres as installed by asdf/mise.
POSTGRES_BASE_DB_NAME = "hanami_cli_test"
POSTGRES_BASE_URL = ENV.fetch("POSTGRES_BASE_URL", "postgres://postgres@localhost:5432/#{POSTGRES_BASE_DB_NAME}")
POSTGRES_BASE_URI = URI(POSTGRES_BASE_URL)

RSpec.configure do |config|
  # Drop all databases with names starting with POSTGRES_URL_BASE
  config.after :each, :postgres do
    cmd_env = {
      "PGHOST" => POSTGRES_BASE_URI.host,
      "PGPORT" => POSTGRES_BASE_URI.port.to_s,
      "PGUSER" => POSTGRES_BASE_URI.user,
      "PGPASSWORD" => POSTGRES_BASE_URI.password
    }

    db_prefix = POSTGRES_BASE_URI.path.sub(%r{^/}, "")
    psql_list, status = Open3.capture2(cmd_env, "psql -t -A -c '\\l #{db_prefix}*'")

    test_databases = psql_list.split("\n").map { _1.split("|").first }
    test_databases.each do |database|
      system(cmd_env, "dropdb --force #{database}")
    end
  end
end
