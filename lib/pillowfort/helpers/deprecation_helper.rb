# This module establishes convenience methods related to adding
# deprecation messages.
#

module Pillowfort
  module Helpers
    module DeprecationHelper

      # This method prints a deprecation warning for the specified
      # method name and refers the user to the new method name.
      #
      def self.warn(klass_name, bad, good)
        head = "********** PILLOWFORT WARNING - #{ klass_name }"
        msg  = "The method `#{ bad }` will be deprecated in the next major release. Please use `#{ good }` instead."

        puts "#{ head }: #{ msg }"
      end

    end

  end
end
