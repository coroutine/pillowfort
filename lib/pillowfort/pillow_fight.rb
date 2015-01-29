module Pillowfort::PillowFight
  def self.error_message(msg)
    puts "\e[31m"
    puts '*'*80
    puts "#{' '*34}Pillow Fight!"
    puts '*'*80
    puts msg
    puts '*'*80
    puts "\e[0m"
  end
end
