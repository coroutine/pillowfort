module Pillowfort
  module ModelFinder
    def find_by_email_case_insensitive(email)
      find_by("lower(email) = ?", email.downcase)
    end
  end
end
