module Pillowfort

  # These methods extend the Pillowfort module to allow an initializer
  # access to a simple configuration object.
  #
  class << self
    def configure(&block)
      yield config
    end

    def config
      @config ||= Pillowfort::Configuration.new
    end
  end

  # This is the configuration object for Pillowfort. It is a simple
  # class that extends ActiveSupport::Configurable so we can add
  # options and default values easily.
  #
  class Configuration
    include ActiveSupport::Configurable

    #========== RESOURCE ==================================

    # resource_class: <default> :user
    config_accessor :resource_class do
      :user
    end

    # password_min_length: <default> 8
    config_accessor :password_min_length do
      8
    end


    #========== TOKENS ====================================

    # token_class: <default> :pillowfort_token
    config_accessor :token_class do
      :pillowfort_token
    end

    # activation_token_ttl: <default> 7.days
    config_accessor :activation_token_ttl do
      7.days
    end

    # password_reset_token_ttl: <default> 7.days
    config_accessor :password_reset_token_ttl do
      7.days
    end

    # session_token_ttl: <default> 1.day
    config_accessor :session_token_ttl do
      1.day
    end

  end
end
