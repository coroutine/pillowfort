require 'bcrypt'

module Pillowfort
  module Concerns::ModelAuthentication
    extend ActiveSupport::Concern
    include BCrypt

    included do

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

      def password
        @password ||= Password.new encrypted_password
      end

      def password=(password)
        @password = Password.create password
        self.encrypted_password = @password
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
          user = find_by_email(email)
          if user

            # if the user token is expired, reset it and
            # return false, triggering a 401
            if user.token_expired?
              user.reset_auth_token!
              return false
            else
              if secure_compare(user.auth_token, token)

                # If the user successfully authenticates within the alotted window
                # of time, we'll extend the window.
                user.send :touch_token_expiry!
                yield user
              end
            end
          end
        end
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
