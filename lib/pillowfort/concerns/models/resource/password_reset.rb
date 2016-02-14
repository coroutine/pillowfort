module Pillowfort
  module Concerns
    module Models
      module Resource

        # This module is designed to be included in the model you configure
        # as the `resource_class`.  It provides helper methods for
        # creating and confirming password reset tokens.
        #
        module PasswordReset
          extend ActiveSupport::Concern


          #------------------------------------------------
          # Class Methods
          #------------------------------------------------

          class_methods do

            # This method locates the user record and returns
            # it if the supplied token matches and is
            # resettable.
            #
            def find_by_password_reset_token(email, token)
              email = email.to_s.downcase.strip
              token = token.to_s.strip

              if resource = self.where(email: email).first
                if resource.password_resettable?
                  if resource.password_reset_token.secure_compare(token)
                    yield resource
                  else
                    raise Pillowfort::NotAuthenticatedError       # token invalid
                  end
                else
                  raise Pillowfort::NotAuthenticatedError         # not resettable
                end
              else
                raise Pillowfort::NotAuthenticatedError           # no resource
              end
            end

          end


          #------------------------------------------------
          # Public Methods
          #------------------------------------------------

          # This method determines whether or not the resource
          # is valid for password reset.
          #
          def password_resettable?
            token = password_reset_token
            !!(token && !token.expired? && !token.confirmed?)
          end

          # This method is a public interface for accepting a
          # password reset of the resource.
          #
          def confirm_password_reset!
            if password_resettable?
              password_reset_token.confirm!
              self
            else
              raise Pillowfort::TokenStateError
            end
          end

          # This method is a public interface that allows
          # controllers to interact with the password reset token
          # in a relatively decoupled way.
          #
          def require_password_reset!
            token = password_reset_token || build_password_reset_token
            token.reset!
            token
          end

        end

      end
    end
  end
end
