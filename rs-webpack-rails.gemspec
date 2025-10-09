$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "webpack/rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rs-webpack-rails"
  s.version     = Webpack::Rails::VERSION
  s.authors     = ["glebtv", "Michael Pearson"]
  s.email       = ["glebtv@gmail.com", "mipearson@gmail.com"]
  s.homepage    = "https://gitlab.com/rocket-science/webpack-rails"
  s.summary     = "Webpack 5 integration for Rails 7+ with Propshaft"
  s.description = "Integrates Webpack 5 with Rails 7+ and Propshaft asset pipeline. Provides seamless asset compilation, digest stamping, and development server support."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib,example}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency "rails", ">= 7.0.0"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "capybara"
  s.add_development_dependency "cuprite"
  s.add_development_dependency "database_cleaner-active_record"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rubocop"
  s.add_development_dependency "simplecov"

  s.add_dependency "railties", ">= 7.0.0"
  s.add_dependency "propshaft", ">= 0.6.0"
  s.required_ruby_version = '>= 3.0.0'
end
