require "uri"

module Hanami
  module CLI
    module Commands
      module DB
        module Utils
          class DatabaseConfig
            attr_reader :uri

            def initialize(database_url)
              @uri = URI(database_url)
            end

            def hostname
              uri.hostname
            end
            alias_method :host, :hostname

            def user
              uri.user
            end
            alias_method :username, :user

            def password
              uri.password
            end
            alias_method :pass, :password

            def port
              uri.port
            end

            def db_name
              @db_name ||= uri.path.gsub(/\A\//, "")
            end

            def db_type
              uri.scheme
            end
          end
        end
      end
    end
  end
end
