$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'pillowfort/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name                  = 'pillowfort'
  s.version               = Pillowfort::VERSION
  s.authors               = ['Tim Lowrimore','John Dugan']
  s.email                 = ['tlowrimore@coroutine.com']
  s.homepage              = 'https://github.com/coroutine/pillowfort'
  s.summary               = 'Pillowfort is a opinionated, no bullshit, session-less authentication engine for Rails APIs.'
  s.description           = 'Pillowfort is nothing more than a handful of Rails API authentication concerns, bundled up for distribution and reuse. It has absolutely no interest in your application. All it cares about is token management. How you integrate Pillowfort\'s tokens into your application is entirely up to you. You are, presumably, paid handsomely to make decisions like that.'
  s.license               = 'MIT'
  s.required_ruby_version = '>= 2.2'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['spec/**/*']

  s.add_dependency 'rails',   '>= 5.1', '< 6.0'
  s.add_dependency 'scrypt',  '>= 2.0', '< 4.0'

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'rspec-its'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'pry-nav'
end
