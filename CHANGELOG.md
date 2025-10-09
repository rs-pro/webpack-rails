# CHANGELOG

## v0.13.1 - Rails 7/8 + Propshaft Modernization (2025-10-09)

### Breaking Changes
 * **Rails 7+ required** - Minimum Rails version upgraded from 4.0 to 7.0
 * **Ruby 3.0+ required** - Minimum Ruby version upgraded from 2.0 to 3.0
 * **Webpack 5 required** - Updated for Webpack 5 (from Webpack 3)
 * **Propshaft integration** - Now uses Propshaft asset pipeline (Rails 8 default)
 * Removed legacy Manifest class - now relies on Propshaft for asset resolution

### New Features
 * **Propshaft integration** - Webpack output directory automatically added to Propshaft load path
 * **`.digested` extension support** - Webpack outputs with `.digested` extension to prevent Propshaft re-digesting
 * **Simplified helper** - `webpack_asset_paths` now wraps Propshaft's `asset_path` for seamless integration
 * **Rails 8 compatibility** - Full support for Rails 8 without Sprockets dependency
 * **Modern webpack config** - Updated example config for Webpack 5 with modern plugins
 * **Enhanced Capistrano tasks** - Improved deployment integration with Capistrano 3

### Developer Experience
 * **Comprehensive test suite** - 76+ test examples with RSpec Rails, Capybara, and Cuprite
 * **Full dummy app** - spec/dummy Rails 8 application for testing
 * **Modern dependencies** - Updated to webpack-manifest-plugin v5, webpack-dev-server v4
 * **Improved generator** - Better output and instructions for Rails 7/8 setup
 * **Updated documentation** - Complete README rewrite with modern examples

### Configuration Changes
 * `config.webpack.dev_server.https_verify_peer` now defaults to `true` (was `false`)
 * Webpack output uses `.digested` extension pattern: `[name]-[contenthash].digested.js`
 * Babel loader integration for ES6+ support out of the box
 * Improved CORS and dev server configuration

### Technical Details
 * Helper now uses `asset_path` from Propshaft instead of custom manifest loading
 * Railtie checks for `config.assets` presence (Rails 8 compatibility)
 * Webpack config uses modern module.exports with const/let
 * Package.json updated with npm scripts for build and dev
 * Maintains 100% backwards compatible API for legacy `webpack_asset_paths` helper

### Migration Guide
For existing projects upgrading from older versions:
1. Update Gemfile: `gem 'rs-webpack-rails', '~> 0.13.1'`
2. Update package.json dependencies to Webpack 5
3. Modify webpack.config.js to use `.digested` extension
4. Run `bundle install` and `npm install`
5. Test with `rake webpack:compile`

See README.md for detailed migration instructions.

## v0.9.10

 * Only error if manifest error was a module build failure (Juan-Carlos Medina and Naomi Jacobs <pair+juanca+naomi@mavenlink.com>)
 * Change dependency to railties (Mike Auclair <mike@mikeauclair.com>)
 * Only enable dev server in development & test (Agis Anastasopoulos <agis.anast@gmail.com>)
 * Use existing NODE_ENV if available (Alex <alexkrolick@users.noreply.github.com>)
 * Switched README & generators to use yarn over npm
 * Allow SSL certificate verification for localhost connections (Marek Hulan <mhulan@redhat.com>)
