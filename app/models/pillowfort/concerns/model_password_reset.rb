require 'pillowfort/model_context'
require 'pillowfort/token_generator'
require 'pillowfort/model_finder'

module Pillowfort
  module Concerns::ModelPasswordReset
    extend ActiveSupport::Concern

    included do
      def create_password_reset_token(expiry: nil)
        expiry ||= 1.hour.from_now
        self.password_reset_token = generate_password_reset_token
        self.password_reset_token_expires_at = expiry
      end

      def password_token_expired?
        if password_reset_token_expires_at
          password_reset_token_expires_at <= Time.now
        else
          true
        end
      end

      def clear_password_reset_token
        update_columns \
          password_reset_token: nil,
          password_reset_token_expires_at: nil
      end

      private

      def generate_password_reset_token
        resource_class = self.class
        loop do
          token = resource_class.friendly_token
          break token unless resource_class.where(password_reset_token: token).first
        end
      end
    end

    module ClassMethods
      include Pillowfort::TokenGenerator
      include Pillowfort::ModelFinder

      def find_and_validate_password_reset_token(email, token)
        return false if email.blank? || token.blank?

        transaction do
          if resource = find_by_email_case_insensitive(email)
            if resource.password_token_expired?
              return false
            else
              if secure_compare(resource.password_reset_token, token)
                yield resource if block_given?
              end
            end
          end
        end
      end
    end
  end
end