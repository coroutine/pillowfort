module Pillowfort
  module Concerns
    module Models
      module Token

        # This module is designed to be included in the model you configure
        # as the `token_class`.  It handles establishing the appropriate
        # validations and provides helper methods for creating and comparing
        # secrets.
        #
        module Base
          extend ActiveSupport::Concern

          #------------------------------------------------
          # Configuration
          #------------------------------------------------

          included do

            # constants
            TOKEN_TYPES ||= %w{ activation password_reset session }

            # callbacks
            before_validation :normalize_type
            before_validation :normalize_realm
            before_validation :reset_secret, on: :create

            # turn off fucking sti
            self.inheritance_column = :_sti_disabled

            # associations
            belongs_to :resource, class_name:  Pillowfort.config.resource_class.to_s.classify

            # validations
            validates :resource, presence: true
            validates :type,     presence: true, inclusion: { in: TOKEN_TYPES }
            validates :secret,   presence: true, uniqueness: { scope: [:type] }
            validates :realm,    presence: true, uniqueness: { scope: [:resource_id, :type] }

          end


          #------------------------------------------------
          # Class Methods
          #------------------------------------------------

          class_methods do

            # This method provides an application-wide utility
            # for generating friendly secrets.
            #
            def friendly_secret(length=40)
              SecureRandom.base64(length).tr('+/=lIO0', 'pqrsxyz').first(length)
            end

            # DEPRECATED: This method should be removed in the next
            # major release of the library.
            #
            def friendly_token(length=40)
              Pillowfort::Helpers::DeprecationHelper.warn(self.name, :friendly_token, :friendly_secret)
              friendly_secret(length)
            end

          end


          #------------------------------------------------
          # Public Methods
          #------------------------------------------------

          #========== ATTRIBUTES ==========================

          # DEPRECATED: This method should be removed in the next
          # major release of the library.
          #
          def token=(value)
            Pillowfort::Helpers::DeprecationHelper.warn(self.class.name, :token=, :secret=)
            send(:secret=, value)
          end

          # DEPRECATED: This method should be removed in the next
          # major release of the library.
          #
          def token
            Pillowfort::Helpers::DeprecationHelper.warn(self.class.name, :token, :secret)
            send(:secret)
          end


          #========== COMPARISONS =========================

          # This method performs a constant-time comparison
          # of pillowfort secrets in an effort to confound
          # timing attacks.
          #
          # This was lifted verbatim from Devise.
          #
          def secure_compare(value)
            a = self.secret
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
            reset_secret
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
          def reset_secret
            loop do
              self.secret = friendly_secret
              break self.secret unless self.class.where(type: self.type, secret: self.secret).first
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

          # This method produces a random, base64 secret and
          # replaces any potentially problematic characters
          # with nice characters.
          #
          # This was lifted verbatim from Devise.
          #
          def friendly_secret
            self.class.friendly_secret(length)
          end


          #========== TTL =================================

          # This method determines the configured secret length
          # for this token's type.
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
