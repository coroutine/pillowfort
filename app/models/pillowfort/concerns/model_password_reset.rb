require 'pillowfort/model_context'

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
        password_reset_token_expires_at <= Time.now
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

    end
  end
end
