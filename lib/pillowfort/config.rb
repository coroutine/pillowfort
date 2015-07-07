module Pillowfort
  class << self
    def configure(&block)
      yield config
    end

    def config
      @config ||= Pillowfort::Configuration.new
    end
  end

  class Configuration
    include ActiveSupport::Configurable

    # auth_token_ttl: <default> 1.day
    config_accessor :auth_token_ttl do
      1.day
    end

    # min_password_length: <default> 8
    config_accessor :min_password_length do
      8
    end
  end
end
