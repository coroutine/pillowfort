module Pillowfort
  module Concerns
    module Models
      module Resource

        # This module is designed to be included in the model you configure
        # as the `resource_class`.  It handles establishing the appropriate
        # validations and provides helper methods for authenticating sessions
        # and interacting with session tokens.
        #
        # Behaviors related to activation and password resets are handled
        # in seaparate modules.
        #
        module Base
          extend ActiveSupport::Concern

          #--------------------------------------------------
          # Configuration
          #--------------------------------------------------

          included do

            # callbacks
            before_validation :normalize_email

            # attributes
            attr_reader :password
            attr_reader :password_confirmation

            # associations
            has_one  :activation_token,      -> { where(type: 'activation', realm: 'application') },
                                              class_name: Pillowfort.config.token_class.to_s.classify,
                                              foreign_key: :resource_id
            has_one  :password_reset_token,  -> { where(type: 'password_reset', realm: 'application') },
                                              class_name: Pillowfort.config.token_class.to_s.classify,
                                              foreign_key: :resource_id
            has_many :session_tokens,        -> { where(type: 'session') },
                                              class_name: Pillowfort.config.token_class.to_s.classify,
                                              foreign_key: :resource_id

            # validations
            validates_presence_of      :email
            validates_uniqueness_of    :email
            validates_presence_of      :password, unless: :password_digest?
            validates_length_of        :password, minimum: Pillowfort.config.password_min_length, allow_nil: true
            validates_confirmation_of  :password, allow_nil: true

          end


          #--------------------------------------------------
          # Class Methods
          #--------------------------------------------------

          class_methods do

            # This method accepts authentication information and checks
            # the database for the email and session token. If all goes
            # well, we reset the session token with the realm; otherwise
            # we raise the appropriate error.
            #
            def authenticate_securely(email, token, realm='application')
              email = email.to_s.downcase.strip
              token = token.to_s.strip
              realm = realm.to_s.downcase.strip

              if email.blank? || token.blank?
                raise Pillowfort::NotAuthenticatedError               # no anything
              else
                transaction do
                  if resource = self.where(email: email).first
                    if resource.activated?
                      if session_token = resource.session_tokens.where(realm: realm).first

                        if session_token.expired?
                          session_token.reset!
                          raise Pillowfort::NotAuthenticatedError     # token expired
                        else
                          if session_token.secure_compare(token)
                            session_token.refresh!
                            yield resource                            # success!
                          else
                            raise Pillowfort::NotAuthenticatedError   # bad token
                          end
                        end

                      else
                        raise Pillowfort::NotAuthenticatedError       # no token
                      end
                    else
                      raise Pillowfort::NotActivatedError             # not activated
                    end
                  else
                    raise Pillowfort::NotAuthenticatedError           # no resource
                  end
                end
              end
            end

            # This method accepts authentication information and checks
            # the database for the email and password digest. If all goes
            # well, we reset the session token with the realm; otherwise
            # we raise the appropriate error.
            #
            def find_and_authenticate(email, password, realm='application')
              resource = self.where(email: email.to_s.downcase).first

              if resource && resource.authenticate(password)
                if resource.activated?
                  resource.reset_session!(realm)
                  resource
                else
                  raise Pillowfort::NotActivatedError
                end
              else
                raise Pillowfort::NotAuthenticatedError
              end
            end

          end


          #--------------------------------------------------
          # Public Methods
          #--------------------------------------------------

          #========== PASSWORDS =============================

          # This method accepts an unencrypted password value,
          # stores it in an instance variable, and uses it
          # to generate a secure one-way hash.
          #
          # For now, we just uses default costs. ~200ms, 1MB
          #
          def password=(unencrypted)
            pword = unencrypted.strip

            if pword.blank?
              self.password_digest = nil
            else
              @password = pword
              self.password_digest = SCrypt::Password.create(pword)
            end
          end

          # This method stores the unencrypted password
          # confirmation value in an instance variable to
          # facilitate validations.
          #
          def password_confirmation=(unencrypted)
            @password_confirmation = unencrypted
          end

          # This method resets the resource's password by
          # assigning a random token to :password and
          # :password_confirmation.
          #
          def reset_password
            random = SecureRandom.base64(30).tr('+/=lIO0', 'pqrsxyz')

            self.password              = random
            self.password_confirmation = random
          end


          #========== ACTIVATION ============================

          # This method always returns true in its default form.
          # If you want actual activation behavior, please see
          # the Activation model concern, which will override
          # this method and add several others.
          #
          def activated?
            true
          end


          #========== SESSION ===============================

          # This method accepts a plain text password and
          # determines whether or not it matches the
          # password digest for the current user.
          #
          def authenticate(unencrypted)
            SCrypt::Password.new(password_digest) == unencrypted && self
          end

          # This method delegates the token reset process to the
          # model's session token. A session token will be created
          # if none exists.
          #
          def reset_session!(realm='application')
            token = session_tokens.where(realm: realm).first_or_initialize
            token.reset!
            token.token
          end


          #--------------------------------------------------
          # Private Methods
          #--------------------------------------------------
          private

          #========== NORMALIZATION =========================

          # This method ensures all emails are stored in a
          # similar string format to facilitate lookups.
          #
          def normalize_email
            if self.email.present?
              self.email = self.email.downcase.strip
            end
          end

        end

      end
    end
  end
end
