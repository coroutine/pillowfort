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
          # Class Methods
          #------------------------------------------------

          class_methods do

            # This method locates the user record and returns
            # it if the supplied secret matches and is
            # activatable.
            #
            def find_by_activation_secret(email, secret, &block)
              email  = email.to_s.downcase.strip
              secret = secret.to_s.strip

              if resource = self.where(email: email).first
                if resource.activatable?
                  if resource.activation_token.secure_compare(secret)
                    yield resource
                  else
                    raise Pillowfort::NotAuthenticatedError       # token invalid
                  end
                else
                  raise Pillowfort::NotAuthenticatedError         # not activatable
                end
              else
                raise Pillowfort::NotAuthenticatedError           # no resource
              end
            end

            # DEPRECATED: This method should be removed in the next
            # major release of the library.
            #
            def find_by_activation_token(email, secret, &block)
              Pillowfort::Helpers::DeprecationHelper.warn(self.name, :find_by_activation_token, :find_by_activation_secret)
              find_by_activation_secret(email, secret, &block)
            end

          end


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
