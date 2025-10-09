# Webpack-Rails Test Suite

This comprehensive test suite validates the modernized webpack-rails gem with propshaft integration.

## Test Structure

```
spec/
├── spec_helper.rb              # Basic RSpec configuration with SimpleCov
├── rails_helper.rb             # Rails-specific configuration
├── support/
│   └── webpack_helpers.rb      # Helper methods for webpack testing
├── webpack/
│   └── rails/
│       ├── helper_spec.rb      # Tests for webpack_asset_paths helper
│       └── railtie_spec.rb     # Tests for Railtie configuration
├── features/
│   └── webpack_integration_spec.rb  # Integration tests
└── rake_tasks/
    └── webpack_compile_spec.rb      # Tests for webpack:compile task
```

## Test Files

### 1. spec_helper.rb
Basic RSpec configuration with:
- SimpleCov code coverage setup (HTML and JSON formatters)
- Standard RSpec best practices
- 80% minimum coverage requirement
- Filters for spec/, vendor/, and dummy/ directories

### 2. rails_helper.rb
Rails-specific testing configuration:
- Loads the spec/dummy Rails app
- Configures Capybara with Cuprite for browser testing
- Sets up DatabaseCleaner for test isolation
- Includes custom webpack helpers
- Creates webpack directory before each test

### 3. spec/webpack/rails/helper_spec.rb
Tests the `webpack_asset_paths` helper method:
- Returns array of asset paths
- Handles different file extensions (js, css)
- Tests ignore_missing flag behavior
- Validates propshaft integration
- Tests empty/nil source handling
- Verifies .digested extension preservation

**Key Test Cases:**
- ✓ Returns an array
- ✓ Returns single element array
- ✓ Handles .js and .css extensions
- ✓ Raises error when asset not found (ignore_missing: false)
- ✓ Returns empty string when asset not found (ignore_missing: true)
- ✓ Uses propshaft's asset_path helper
- ✓ Preserves .digested extension

### 4. spec/webpack/rails/railtie_spec.rb
Tests the Webpack Railtie configuration:
- Validates default configuration values
- Tests asset path initialization
- Verifies helper inclusion in ActionView
- Tests rake task registration
- Validates propshaft integration

**Key Test Cases:**
- ✓ Adds webpack config to Rails.config
- ✓ Sets correct default paths and ports
- ✓ Adds webpack output_dir to assets.paths
- ✓ Includes helper in ActionView::Base
- ✓ Loads webpack:compile rake task
- ✓ Supports per-environment configuration

### 5. spec/features/webpack_integration_spec.rb
End-to-end integration tests:
- Tests webpack asset serving
- Validates helper usage in views
- Tests .digested extension handling
- Verifies multiple entry points

**Key Test Cases:**
- ✓ Serves webpack assets from public/webpack/
- ✓ Correct Content-Type headers for JS and CSS
- ✓ webpack_asset_paths helper works in views
- ✓ Serves assets with .digested extension
- ✓ Webpack directory in propshaft load paths
- ✓ Multiple webpack entries work independently

### 6. spec/rake_tasks/webpack_compile_spec.rb
Tests the webpack:compile rake task:
- Task definition and dependencies
- Environment variable handling
- Error handling for missing files
- Asset compilation verification

**Key Test Cases:**
- ✓ Task is defined with proper description
- ✓ Sets TARGET and NODE_ENV variables
- ✓ Executes webpack with correct parameters
- ✓ Raises error for missing webpack binary
- ✓ Raises error for missing config file
- ✓ Creates assets in public/webpack/
- ✓ Respects custom configuration paths

### 7. spec/support/webpack_helpers.rb
Helper methods for testing:
- `create_webpack_asset(filename, content)` - Create test assets
- `cleanup_webpack_assets` - Clean up test files
- `simulate_webpack_compile(entry_name, options)` - Simulate compilation
- `create_webpack_manifest(entries)` - Create manifest.json

## Running the Tests

### Run all tests:
```bash
bundle exec rspec
```

### Run specific test file:
```bash
bundle exec rspec spec/webpack/rails/helper_spec.rb
```

### Run with coverage:
```bash
COVERAGE=true bundle exec rspec
```

### Run feature tests (slower, with browser):
```bash
bundle exec rspec spec/features/
```

### Run unit tests only (fast):
```bash
bundle exec rspec spec/webpack/
```

## Test Dependencies

The test suite requires these gems (add to gemspec or Gemfile):

```ruby
# Testing framework
gem 'rspec-rails', '~> 6.1'

# Browser testing
gem 'capybara', '~> 3.40'
gem 'cuprite', '~> 0.15'  # Chrome/Chromium driver for Capybara

# Database management
gem 'database_cleaner-active_record', '~> 2.1'

# Code coverage
gem 'simplecov', require: false
gem 'simplecov_json_formatter', require: false

# Test database
gem 'sqlite3', '~> 1.4'
```

## Key Testing Concepts

### Propshaft Integration
The tests verify that webpack-rails properly integrates with propshaft:
1. Webpack output directory is added to asset load paths
2. Assets with .digested extension are preserved
3. The asset_path helper resolves webpack assets
4. Assets are served correctly through propshaft

### .digested Extension
Webpack assets use the `.digested` extension to signal to propshaft that:
- The filename already contains a content hash
- Propshaft should not add another digest
- The original webpack-generated hash is preserved

Example: `application-abc123.digested.js`

### Helper Method Pattern
The `webpack_asset_paths` helper:
- Returns an array for backwards compatibility
- Uses propshaft's `asset_path` under the hood
- Supports extension filtering
- Provides ignore_missing option

### Rake Task Validation
Tests ensure the webpack:compile task:
- Sets correct environment variables
- Validates webpack binary and config exist
- Uses --bail flag for production builds
- Creates assets in the correct directory

## Coverage Goals

The test suite aims for:
- **Minimum 80% code coverage** (enforced by SimpleCov)
- **100% coverage of public APIs** (helpers, rake tasks)
- **Integration testing** of propshaft interaction
- **Error handling** for all failure scenarios

## Continuous Integration

For CI environments, run tests with:

```bash
# Set headless mode for browser tests
HEADLESS=true bundle exec rspec

# Generate coverage reports
COVERAGE=true bundle exec rspec

# Run tests in parallel (if using parallel_tests gem)
bundle exec parallel_rspec spec/
```

## Maintenance Notes

### When Adding New Features
1. Add unit tests in `spec/webpack/rails/`
2. Add integration tests in `spec/features/`
3. Update helper specs if helper behavior changes
4. Add rake task tests if adding new tasks

### When Updating Dependencies
1. Test propshaft integration still works
2. Verify Capybara/Cuprite driver compatibility
3. Check RSpec Rails matchers still work
4. Update SimpleCov filters if needed

### Common Test Patterns

**Testing helper methods:**
```ruby
it 'uses propshaft asset_path' do
  allow(helper).to receive(:asset_path).with('app.js')
    .and_return('/assets/app-hash.digested.js')

  result = helper.webpack_asset_paths('app')
  expect(result.first).to include('digested.js')
end
```

**Testing file creation:**
```ruby
it 'creates webpack assets' do
  create_webpack_asset('test-hash.digested.js')

  expect(File.exist?(webpack_dir.join('test-hash.digested.js')))
    .to be true
end
```

**Testing rake tasks:**
```ruby
it 'executes webpack command' do
  expect_any_instance_of(Object).to receive(:sh)
    .with(/webpack.*--config.*--bail/)

  Rake::Task['webpack:compile'].invoke
end
```

## Troubleshooting

### Tests failing due to missing webpack directory
Ensure the rails_helper creates the directory:
```ruby
config.before(:each) do
  FileUtils.mkdir_p(Rails.root.join('public/webpack'))
end
```

### Browser tests timing out
Increase Capybara wait time:
```ruby
Capybara.default_max_wait_time = 10
```

### Coverage not reaching 80%
Check which files are not covered:
```bash
open coverage/index.html
```

### Cuprite not starting
Install Chrome or Chromium:
```bash
# Ubuntu/Debian
sudo apt-get install chromium-browser

# macOS
brew install chromium
```

## Test Output Example

```
Webpack::Rails::Helper
  #webpack_asset_paths
    with propshaft integration
      ✓ returns an array
      ✓ returns array with one element for single asset
      with different extensions
        ✓ handles .js extension
        ✓ handles .css extension
        ✓ defaults to .js extension when not specified

Webpack::Railtie
  configuration
    ✓ adds webpack configuration to Rails config
    ✓ sets default output_dir
    dev_server configuration
      ✓ sets default dev_server port

Webpack Integration
  webpack assets serving
    with compiled webpack assets
      ✓ serves webpack assets from public/webpack directory
      ✓ includes correct content type for JavaScript

webpack:compile rake task
  task definition
    ✓ defines webpack:compile task
    ✓ has proper description
  task execution
    ✓ executes webpack with correct parameters
    ✓ creates assets in public/webpack/ directory

Finished in 2.34 seconds (files took 1.23 seconds to load)
42 examples, 0 failures

Coverage report generated for RSpec to /coverage
89.23% covered at 1.2 hits/line
```

## Future Enhancements

Consider adding tests for:
1. Source map handling
2. Hot module replacement (HMR) in development
3. Multiple webpack configurations
4. Asset preloading/prefetching
5. Service worker integration
6. Code splitting validation
7. Tree shaking verification
8. Performance benchmarks

## Contributing

When adding new tests:
1. Follow existing naming conventions
2. Use descriptive test names (what, not how)
3. Group related tests in contexts
4. Keep tests focused and isolated
5. Mock external dependencies
6. Clean up test artifacts
7. Document complex test scenarios
