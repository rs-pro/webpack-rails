require_relative 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'

# Load the Rails test application
require_relative 'dummy/config/environment'

require 'rspec/rails'
require 'capybara/rails'
require 'capybara/cuprite'
require 'database_cleaner/active_record'

# Load support files
Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

# Configure Capybara to use webrick server (since puma is not available)
Capybara.server = :webrick

# Configure Capybara with Cuprite for modern browser testing
Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1200, 800],
    browser_options: { 'no-sandbox' => nil },
    inspector: ENV['INSPECTOR'] == 'true',
    headless: ENV['HEADLESS'] != 'false'
  )
end

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :cuprite
Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Database cleaner setup
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # Include Capybara DSL in feature specs
  config.include Capybara::DSL, type: :feature

  # Helper method to create webpack assets for testing
  config.before(:each) do
    # Ensure webpack output directory exists
    webpack_dir = Rails.root.join('public/webpack')
    FileUtils.mkdir_p(webpack_dir) unless webpack_dir.exist?
  end
end
