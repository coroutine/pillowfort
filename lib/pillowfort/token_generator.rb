module Pillowfort
  module TokenGenerator
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
