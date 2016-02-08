module Pillowfort
  module Helpers

    # This module establishes convenience methods related to error
    # handling.
    #
    module ErrorHelper

      # This method prints error messages format for the console.
      #
      def self.pillow_fight(msg)
        puts "\e[31m"
        puts '*'*80
        puts "#{' '*34}Pillow Fight!"
        puts '*'*80
        puts msg
        puts '*'*80
        puts "\e[0m"
      end
    end

  end
end
