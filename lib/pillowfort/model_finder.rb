module Pillowfort
  module ModelFinder
    def find_by_email_case_insensitive(email)
      return nil if email.blank?

      find_by("lower(email) = ?", email.downcase.strip)
    end
  end
end
