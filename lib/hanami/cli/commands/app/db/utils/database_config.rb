require "uri"

module Hanami
  module CLI
    module Commands
      module App
        module DB
          # @api private
          module Utils
            # @api private
            class DatabaseConfig
              # @api private
              attr_reader :uri

              # @api private
              def initialize(database_url)
                @uri = URI(database_url)
              end

              # @api private
              def hostname
                uri.hostname
              end
              alias_method :host, :hostname

              # @api private
              def user
                uri.user
              end
              alias_method :username, :user

              # @api private
              def password
                uri.password
              end
              alias_method :pass, :password

              # @api private
              def port
                uri.port
              end

              # @api private
              def db_name
                @db_name ||= uri.path.gsub(/\A\//, "")
              end

              # @api private
              def db_type
                uri.scheme
              end
            end
          end
        end
      end
    end
  end
end
