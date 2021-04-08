# frozen_string_literal: true

require_relative "./slice_context"

module Hanami
  module CLI
    module Generators
      module Monolith
        class ActionContext < SliceContext
          def initialize(inflector, slice, controller, action)
            @controller = controller
            @action = action
            super(inflector, nil, slice)
          end

          def classified_controller_name
            inflector.camelize(controller)
          end

          def classified_action_name
            inflector.classify(action)
          end

          def underscored_controller_name
            inflector.underscore(controller)
          end

          def underscored_action_name
            inflector.underscore(action)
          end

          private

          attr_reader :controller

          attr_reader :action
        end
      end
    end
  end
end
