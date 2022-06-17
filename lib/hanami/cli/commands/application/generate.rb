# frozen_string_literal: true

module Hanami
  module CLI
    module Commands
      module Application
        module Generate
          require_relative "./generate/slice"
          require_relative "./generate/action"
        end
      end
    end
  end
end
