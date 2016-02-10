module Pillowfort
  module Concerns
    module Models
      module Resource

        # This module is designed to be included in the model you configure
        # as the `resource_class`.  It provides helper methods for
        # creating and confirming activation tokens.
        #
        module Activation
          extend ActiveSupport::Concern


          #------------------------------------------------
          # Public Methods
          #------------------------------------------------

          # This method determines whether or not the resource
          # is valid for activation.
          #
          def activatable?
            token = activation_token
            !!(token && !token.expired? && !token.confirmed?)
          end

          # This method determines whether or not the resource
          # has already been activated.
          #
          def activated?
            activation_token && activation_token.confirmed?
          end

          # This method is a public interface for activating
          # the resource.
          #
          def confirm_activation!
            if activatable?
              activation_token.confirm!
              self
            else
              raise Pillowfort::TokenStateError
            end
          end

          # This method is a public interface that allows
          # controllers to interact with the activation token
          # in a relatively decoupled way.
          #
          def require_activation!
            token = activation_token || build_activation_token
            token.reset!
            token
          end

        end

      end
    end
  end
end
