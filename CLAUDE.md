# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

rs-webpack-rails is a Ruby gem that integrates Webpack 5 with Rails 7/8 applications using the Propshaft asset pipeline. It provides seamless JavaScript bundling while leveraging Rails' native asset serving.

## Key Architecture Concepts

### The `.digested` Extension Pattern
The gem uses a unique naming convention where Webpack outputs files with `.digested` extension (e.g., `application-abc123.digested.js`). This signals to Propshaft that the file already contains a content hash and should not be re-digested. This is implemented in:
- Generator templates: `lib/generators/webpack_rails/templates/webpack.config.js`
- Helper that resolves paths: `lib/webpack/rails/helper.rb`

### Integration Points

1. **Railtie** (`lib/webpack/railtie.rb`):
   - Registers the gem with Rails
   - Adds `public/webpack` to Propshaft's asset paths
   - Configures default settings through `Rails.application.config.webpack`

2. **Capistrano Integration** (`lib/capistrano/webpack.rb`, `lib/capistrano/tasks/webpack.rake`):
   - Hooks into deployment pipeline after `deploy:assets:precompile`
   - Supports NVM through `NVM_WRAPPER_PATH` environment variable
   - Passes `:nvm_prefix` from capistrano-nvm to rake tasks when available

3. **Rake Tasks** (`lib/tasks/webpack.rake`):
   - `webpack:compile`: Main compilation task
   - Detects and uses NVM wrapper if `NVM_WRAPPER_PATH` is set
   - Used by both local development and Capistrano deployments

## Development Commands

```bash
# Install dependencies
bundle install
cd spec/dummy && npm install && cd ../..

# Run all tests
bundle exec rspec

# Run specific test
bundle exec rspec spec/webpack/rails/helper_spec.rb

# Run tests with coverage
COVERAGE=true bundle exec rspec

# Lint Ruby code
bundle exec rubocop

# Run dummy app for manual testing
cd spec/dummy
foreman start  # Starts Rails + webpack-dev-server

# Build webpack assets in dummy app
cd spec/dummy
npm run build
# or
NODE_ENV=production npm run build  # For digested files

# Run generator in dummy app (for testing changes)
cd spec/dummy
rails generate webpack_rails:install
```

## CI/CD Pipeline

The project uses GitLab CI with the following structure:
- **setup:dependencies**: Installs Ruby gems and npm packages
- **test:ruby-3.3**, **test:ruby-3.4**: Runs RSpec tests on different Ruby versions
- **test:webpack-compile**: Verifies webpack compilation and digested file generation
- **test:generator**: Tests the Rails generator creates all required files
- **quality:rubocop**: Runs linting
- **quality:bundle-audit**: Security checks

Pipeline configuration prevents duplicate runs through workflow rules.

## Testing Strategy

The test suite (`spec/`) includes:
- **Unit tests** for helpers and manifest handling
- **Integration tests** using a dummy Rails app in `spec/dummy/`
- **Generator tests** that verify file creation
- **Rake task tests** that verify webpack compilation

The dummy app is a minimal Rails 8 application with:
- Propshaft configured
- Webpack configured to output to `public/webpack/`
- Test pages at `/` and `/test` for integration testing

## NVM Support Implementation

The gem supports deployments with NVM (Node Version Manager) through:
1. Capistrano tasks check for `:nvm_prefix` set by capistrano-nvm gem
2. This value is passed as `NVM_WRAPPER_PATH` environment variable
3. The webpack:compile rake task uses this wrapper to execute webpack with correct Node version
4. No guessing or automatic detection - explicit configuration only

## Common Troubleshooting

### "Cannot find module 'fs/promises'" during deployment
This indicates webpack is running with an old Node.js version. Ensure:
1. capistrano-nvm gem is properly configured in your app's Capfile
2. The deployment sets up NVM correctly before running webpack:compile

### Duplicate CI pipelines
The workflow rules in `.gitlab-ci.yml` prevent this. Pipelines run for either merge requests OR branch pushes, never both.

### Missing .digested.js files in CI
The webpack compile test must set `NODE_ENV=production` to generate digested filenames.

## Gem Release Process

Releases are manual due to RubyGems 2FA requirements:
1. Update version in `lib/webpack/rails/version.rb`
2. Update CHANGELOG if present
3. Build gem: `gem build rs-webpack-rails.gemspec`
4. Push to RubyGems manually with 2FA

## Multiple Working Directories

This repository may be worked on alongside:
- `/data/propshaft/` - Propshaft asset pipeline
- `/data/rails/` - Rails framework
- `/data/activeadmin/` - Admin interface framework
- `/data/capistrano-nvm/` - NVM integration for Capistrano
- `/data/capistrano/` - Deployment automation tool

These are available for reference when debugging integration issues.