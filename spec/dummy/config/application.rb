require_relative 'boot'

# Instead of requiring all of Rails, require only what we need
# This avoids ActionText and other components that have issues in test environments
require 'rails'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'active_job/railtie'
require 'action_cable/engine'
# require 'action_text/engine'  # Disabled - causes FrozenError in tests
require 'action_mailbox/engine'
require 'rails/test_unit/railtie'

Bundler.require(*Rails.groups)
require 'webpack/rails'

module Dummy
  class Application < Rails::Application
    config.load_defaults 8.0

    # Configuration for the application, engines, and railties goes here.
    config.eager_load = false

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Use propshaft for asset pipeline (default in Rails 8)
    # Propshaft will be loaded automatically

    # Webpack configuration is set by the Webpack::Railtie
    # Override specific values if needed, but don't reinitialize config.webpack
  end
end
