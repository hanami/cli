module Hanami
  module CLI
    module Commands
      module App
        # The `install` command exists to provide third parties a hook for their own installation
        # behaviour to be run as part of `hanami new`.
        #
        # Third parties should register their install commands like so:
        #
        # ```
        # if Hanami::CLI.within_hanami_app?
        #   Hanami::CLI.after "install", MyHanamiGem::CLI::Commands::Install
        # end
        # ````
        #
        # @since 2.0.0
        # @api private
        class Install < Command
          desc "Install Hanami third-party plugins"

          def call(*)
          end
        end
      end
    end
  end
end
