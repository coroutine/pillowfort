require 'bcrypt'
require 'pillowfort/model_context'
require 'pillowfort/token_generator'
require 'pillowfort/model_finder'

module Pillowfort
  module Concerns::ModelAuthentication
    extend ActiveSupport::Concern
    include BCrypt

    included do
      Pillowfort::ModelContext.model_class = self

      # Provided by Rails
      has_secure_password

      validates :email, presence: true, uniqueness: true
      validates :password,
                length: { minimum: Pillowfort.config.min_password_length },
                allow_nil: true

      before_validation :normalize_email
      before_save       :ensure_auth_token

      def ensure_auth_token
        reset_auth_token if auth_token.blank?
      end

      def reset_auth_token
        self.auth_token             = generate_auth_token
        self.auth_token_expires_at  = generate_expiry
      end

      def reset_auth_token!
        reset_auth_token
        save validate: false
      end

      def auth_token_expired?
        auth_token_expires_at <= Time.now
      end

      private

      def generate_expiry
        Time.now + Pillowfort.config.auth_token_ttl
      end

      def touch_token_expiry!
        update_column :auth_token_expires_at, generate_expiry
      end

      def generate_auth_token
        resource_class = self.class
        loop do
          token = resource_class.friendly_token
          break token unless resource_class.where(auth_token: token).first
        end
      end

      def normalize_email
        if self.email.present?
          self.email = self.email.downcase.strip
        end
      end
    end

    module ClassMethods
      include Pillowfort::TokenGenerator
      include Pillowfort::ModelFinder

      def authenticate_securely(email, token)
        return false if email.blank? || token.blank?

        transaction do
          resource = find_by_email_case_insensitive(email)

          if resource

            # if the resource token is expired, reset it and
            # return false, triggering a 401
            if resource.auth_token_expired?
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
    end
  end
end
