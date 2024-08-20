# frozen_string_literal: true

require "open3"
require "uri"

MYSQL_BASE_DB_NAME = "hanami_cli_test"
# Use "127.0.0.1" instead of "localhost" so MySQL connects with TCP instead of a Unix socket
MYSQL_BASE_URL = ENV.fetch("MYSQL_BASE_URL", "mysql2://root:password@127.0.0.1:3307/#{MYSQL_BASE_DB_NAME}")
MYSQL_BASE_URI = URI(MYSQL_BASE_URL)

RSpec.configure do |config|
  # Drop all databases with names starting with MYSQL_URL_BASE
  config.after :each, :mysql do
    mysql_cli_env = {"MYSQL_PWD" => MYSQL_BASE_URI.password}
    mysql_cli_args = [
      "mysql",
      "--host=#{MYSQL_BASE_URI.host}",
      "--port=#{MYSQL_BASE_URI.port}",
      "--protocol=TCP",
      "--user=#{MYSQL_BASE_URI.user}",
      "--batch"
    ].join(" ")

    mysql_databases, _ = Open3.capture2(
      mysql_cli_env, mysql_cli_args + %( -e "SHOW DATABASES")
    )

    test_db_prefix = MYSQL_BASE_URI.path.sub(%r{^/}, "")
    test_databases = mysql_databases
      .split("\n")
      .then { Array(_1[1..]) } # Ignore the header row
      .select { _1.start_with?(test_db_prefix) }

    test_databases.each do |database|
      system(mysql_cli_env, mysql_cli_args + %( -e "DROP DATABASE #{database}"))
    end
  end
end
