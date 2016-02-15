module Pillowfort
  module Concerns
    module Models
      module Token

        # This module is designed to be included in the model you configure
        # as the `token_class`.  It handles establishing the appropriate
        # validations and provides helper methods for creating and comparing
        # tokens.
        #
        module Base
          extend ActiveSupport::Concern

          #------------------------------------------------
          # Configuration
          #------------------------------------------------

          included do

            # constants
            TYPES = %w{ activation password_reset session }

            # callbacks
            before_validation :normalize_type
            before_validation :normalize_realm
            before_validation :reset_token,  on: :create

            # turn off fucking sti
            self.inheritance_column = :_type_disabled

            # associations
            belongs_to :resource, class_name:  Pillowfort.config.resource_class.to_s.classify

            # validations
            validates :resource, presence: true
            validates :type,     presence: true, inclusion: { in: TYPES }
            validates :token,    presence: true, uniqueness: { scope: [:type] }
            validates :realm,    presence: true, uniqueness: { scope: [:resource_id, :type] }

          end


          #------------------------------------------------
          # Class Methods
          #------------------------------------------------

          class_methods do

            # This method provides an application-wide utility
            # for generating friendly tokens.
            #
            def friendly_token(length=30)
              SecureRandom.base64(length).tr('+/=lIO0', 'pqrsxyz')
            end

          end


          #------------------------------------------------
          # Public Methods
          #------------------------------------------------

          #========== COMPARISONS =========================

          # This method performs a constant-time comparison
          # of pillowfort tokens in an effort to confound
          # timing attacks.
          #
          # This was lifted verbatim from Devise.
          #
          def secure_compare(value)
            a = self.token
            b = value

            return false if a.blank? || b.blank? || a.bytesize != b.bytesize
            l = a.unpack "C#{a.bytesize}"

            res = 0
            b.each_byte { |byte| res |= byte ^ l.shift }
            res == 0
          end


          #========== CONFIRMATION ========================

          def confirm
            unless confirmed?
              self.confirmed_at = Time.now
            end
          end

          def confirm!
            confirm
            save!
          end

          def confirmed?
            confirmed_at?
          end


          #========== EXPIRATION ==========================

          def expire
            unless expired?
              self.expires_at = Time.now - 1.second
            end
          end

          def expire!
            expire
            save!
          end

          def expired?
            Time.now > expires_at
          end


          #========== RESETS ==============================

          # This method is a public interface that allows the
          # associated resource to extend the token's expiry.
          #
          def refresh!
            refresh_expiry
            save!
          end

          # This method is a public interface that allows the
          # associated resource to reset the token completely.
          #
          def reset!
            reset_token
            refresh_expiry
            reset_confirmation
            save!
          end


          #------------------------------------------------
          # Private Methods
          #------------------------------------------------
          private

          #========== RESETS ==============================

          # This method extends the expiry according to the
          # ttl for the token's type.
          #
          def refresh_expiry
            self.expires_at = Time.now + ttl
          end

          # This method will nullify the token's confirmation
          # timestamp.
          #
          def reset_confirmation
            self.confirmed_at = nil
          end

          # This method will create new tokens in a loop until
          # one is generated that is unique for the token's type.
          #
          def reset_token
            loop do
              self.token = friendly_token
              break self.token unless self.class.where(type: self.type, token: self.token).first
            end
          end


          #========== NORMALIZATION =======================

          # This method ensures all realms are stored in a
          # similar string format to facilitate lookups.
          #
          def normalize_realm
            if self.realm.present?
              self.realm = self.realm.to_s.underscore.strip
            end
          end

          # This method ensures all types are stored in a
          # similar string format to facilitate lookups.
          #
          def normalize_type
            if self.type.present?
              self.type = self.type.to_s.underscore.strip
            end
          end


          #========== TOKEN ===============================

          # This method produces a random, base64 token and
          # replaces any potentially problematic characters
          # with nice characters.
          #
          # This was lifted verbatim from Devise.
          #
          def friendly_token
            self.class.friendly_token(length)
          end


          #========== TTL =================================

          # This method determines the configured length for this
          # token's type.
          #
          def length
            config = Pillowfort.config

            case self.type
            when 'activation'     then config.activation_token_length
            when 'password_reset' then config.password_reset_token_length
            else                       config.session_token_length
            end
          end

          # This method determines the configured ttl for this
          # token's type.
          #
          def ttl
            config = Pillowfort.config

            case self.type
            when 'activation'     then config.activation_token_ttl
            when 'password_reset' then config.password_reset_token_ttl
            else                       config.session_token_ttl
            end
          end

        end

      end
    end
  end
end
