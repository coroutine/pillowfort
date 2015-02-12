require 'pillowfort/model_context'
require 'pillowfort/controller_methods'

module Pillowfort
  module Concerns::ControllerActivation
    extend ActiveSupport::Concern
    include Pillowfort::ControllerMethods

    included do
      before_filter :enforce_account_activation!
    end

    private

    def enforce_account_activation!
      context = Pillowfort::ModelContext
      if resource = self.send(context.resource_reader_name)
        unless resource.activated?
          head :forbidden
        end
      else
        return false
      end
    end

  end
end
