require 'bcrypt'
require 'pillowfort/model_context'

module Pillowfort
  module Concerns::ModelAuthentication
    extend ActiveSupport::Concern
    include BCrypt

    MIN_PASSWORD_LENGTH = 8

    included do
      Pillowfort::ModelContext.model_class = self

      # Provided by Rails
      has_secure_password

      validates :email, presence: true, uniqueness: true
      validates :password, length: { minimum: MIN_PASSWORD_LENGTH }

      before_save :ensure_auth_token

      def ensure_auth_token
        reset_auth_token if auth_token.blank?
      end

      def reset_auth_token
        self.auth_token             = generate_auth_token
        self.auth_token_expires_at  = 1.day.from_now
      end

      def reset_auth_token!
        reset_auth_token
        save validate: false
      end

      def token_expired?
        auth_token_expires_at <= Time.now
      end

      private

      def touch_token_expiry!
        update_column :auth_token_expires_at, 1.day.from_now
      end

      def generate_auth_token
        resource_class = self.class
        loop do
          token = resource_class.friendly_token
          break token unless resource_class.where(auth_token: token).first
        end
      end
    end

    module ClassMethods
      def authenticate_securely(email, token)
        return false if email.blank? || token.blank?

        transaction do
          resource = find_by_email_case_insensitive(email)

          if resource

            # if the resource token is expired, reset it and
            # return false, triggering a 401
            if resource.token_expired?
              resource.reset_auth_token!
              return false
            else
              if secure_compare(resource.auth_token, token)

                # If the resource successfully authenticates within the alotted window
                # of time, we'll extend the window.
                resource.send :touch_token_expiry!
                yield resource
              end
            end
          end
        end
      end

      def find_and_authenticate(email, password)
        resource = find_by_email_case_insensitive(email)
  
        if resource && resource.authenticate(password)
          resource.tap do |u|
            u.reset_auth_token!
          end
        else
          return false
        end
      end

      def find_by_email_case_insensitive(email)
        find_by("lower(email) = ?", email.downcase)
      end

      # constant-time comparison algorithm to prevent timing attacks.  Lifted
      # from Devise.
      def secure_compare(a, b)
        return false if a.blank? || b.blank? || a.bytesize != b.bytesize
        l = a.unpack "C#{a.bytesize}"

        res = 0
        b.each_byte { |byte| res |= byte ^ l.shift }
        res == 0
      end

      # Generates a value for our auth token.  Lifted from Devise.
      def friendly_token
        SecureRandom.base64(32).tr('+/=lIO0', 'pqrsxyz')
      end
    end
  end
end
