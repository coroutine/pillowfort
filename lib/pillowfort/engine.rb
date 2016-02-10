module Pillowfort
  class Engine < ::Rails::Engine

    # isolation
    isolate_namespace Pillowfort

    # generators
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
    end

  end
end
