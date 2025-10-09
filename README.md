# rs-webpack-rails

**Webpack 5 integration for Rails 7+ with Propshaft**

Modern, seamless integration of Webpack 5 with Rails 7/8 and the Propshaft asset pipeline. Build your JavaScript with Webpack's powerful bundling capabilities while leveraging Rails' native asset serving through Propshaft.

[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.0-red.svg)](https://www.ruby-lang.org)
[![Rails](https://img.shields.io/badge/rails-%3E%3D%207.0-red.svg)](https://rubyonrails.org)
[![Webpack](https://img.shields.io/badge/webpack-5.x-blue.svg)](https://webpack.js.org)

## Features

- 🚀 **Webpack 5** support with modern JavaScript bundling
- 💎 **Rails 7/8** integration with Propshaft asset pipeline
- 🔥 **Hot Module Replacement** in development via webpack-dev-server
- 📦 **Automatic digest preservation** with `.digested` extension pattern
- 🎯 **Zero configuration** for standard setups
- 🔄 **Backwards compatible** API with legacy `webpack_asset_paths` helper
- 🚢 **Capistrano 3** deployment support

## Requirements

- Ruby >= 3.0
- Rails >= 7.0
- Webpack 5.x
- Node.js >= 18.x

## How It Works

This gem bridges Webpack and Rails by:

1. **Webpack compiles** your JavaScript to `public/webpack/` with `.digested` extension
2. **Propshaft discovers** these assets automatically (no manifest needed)
3. **Rails helpers** resolve asset paths through Propshaft's manifest
4. **Production serving** happens via standard Rails asset pipeline

### The `.digested` Extension Pattern

Webpack outputs files like `application-abc123def.digested.js`. The `.digested` extension signals to Propshaft that Webpack has already added a content hash, so Propshaft preserves the filename as-is instead of re-digesting it.

**Example flow:**
```
webpack/application.js
  → [Webpack 5 builds]
  → public/webpack/application-abc123.digested.js
  → [Propshaft serves]
  → /assets/application-abc123.digested.js
```

## Installation

### 1. Add the gem

```ruby
# Gemfile
gem 'rs-webpack-rails'
```

```bash
bundle install
```

### 2. Run the generator

```bash
rails generate webpack_rails:install
```

This creates:
- `config/webpack.config.js` - Webpack 5 configuration
- `package.json` - Node.js dependencies
- `webpack/application.js` - Entry point
- `Procfile` - For running dev servers concurrently

### 3. Install Node dependencies

```bash
npm install
```

### 4. Add webpack assets to your layout

```erb
<!-- app/views/layouts/application.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <title>My App</title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <!-- Webpack assets via helper -->
    <%= javascript_include_tag *webpack_asset_paths("application") %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

## Usage

### Development

**Option 1: Using Foreman (recommended)**
```bash
foreman start
```

This starts both:
- Rails server on port 3000
- Webpack dev server on port 3808

**Option 2: Separate terminals**
```bash
# Terminal 1
rails server

# Terminal 2
npm run dev
```

### Production

Compile webpack assets before deploying:

```bash
rake webpack:compile
```

This runs `webpack --config config/webpack.config.js --bail` in production mode, outputting digested assets to `public/webpack/`.

### View Helpers

The gem provides the `webpack_asset_paths` helper that returns an array of asset URLs:

```erb
<!-- JavaScript -->
<%= javascript_include_tag *webpack_asset_paths("application") %>

<!-- CSS (if webpack extracts CSS) -->
<%= stylesheet_link_tag *webpack_asset_paths("application", extension: "css") %>

<!-- Ignore missing assets -->
<%= javascript_include_tag *webpack_asset_paths("admin", ignore_missing: true) %>
```

**Why an array?** Webpack can output multiple files per entry point (main bundle, chunks, source maps). The helper returns all of them.

## Configuration

### Webpack Configuration

The generated `config/webpack.config.js` is pre-configured for Rails integration:

```javascript
// config/webpack.config.js
const path = require('path');
const { WebpackManifestPlugin } = require('webpack-manifest-plugin');

const production = process.env.NODE_ENV === 'production';
const devServerPort = 3808;

module.exports = {
  mode: production ? 'production' : 'development',

  entry: {
    application: './webpack/application.js'
  },

  output: {
    path: path.join(__dirname, '../public/webpack'),
    publicPath: production ? '/webpack/' : `http://localhost:${devServerPort}/webpack/`,

    // Important: .digested extension prevents Propshaft from re-digesting
    filename: production ? '[name]-[contenthash].digested.js' : '[name].js',
    chunkFilename: production ? '[name]-[contenthash].digested.chunk.js' : '[name].chunk.js',
  },

  plugins: [
    new WebpackManifestPlugin({
      publicPath: production ? '/webpack/' : `http://localhost:${devServerPort}/webpack/`,
      writeToFileEmit: true,
    })
  ],

  devServer: {
    port: devServerPort,
    hot: true,
    headers: { 'Access-Control-Allow-Origin': '*' },
  }
};
```

### Rails Configuration

Default configuration in `config/application.rb`:

```ruby
# These are set automatically by the gem with sensible defaults
config.webpack.config_file = 'config/webpack.config.js'
config.webpack.binary = 'node_modules/.bin/webpack'
config.webpack.output_dir = 'public/webpack'
config.webpack.public_path = 'webpack'
config.webpack.manifest_filename = 'manifest.json'

# Dev server settings
config.webpack.dev_server.host = proc { request.host }  # Dynamic host
config.webpack.dev_server.port = 3808
config.webpack.dev_server.enabled = Rails.env.development? || Rails.env.test?
```

### Custom Configuration

Override defaults in your `config/application.rb` or environment files:

```ruby
# config/application.rb
config.webpack.output_dir = 'public/assets/webpack'  # Custom output directory
config.webpack.dev_server.port = 8080                # Custom dev server port

# For Docker environments
config.webpack.dev_server.manifest_host = 'webpack'  # Container hostname
config.webpack.dev_server.manifest_port = 3808
```

## Multiple Entry Points

Add multiple entry points in your webpack config:

```javascript
// config/webpack.config.js
module.exports = {
  entry: {
    application: './webpack/application.js',
    admin: './webpack/admin.js',
    mobile: './webpack/mobile.js'
  },
  // ... rest of config
};
```

Use in views:

```erb
<%= javascript_include_tag *webpack_asset_paths("admin") %>
```

## CSS Support

To bundle CSS with Webpack, use `mini-css-extract-plugin`:

```bash
npm install --save-dev mini-css-extract-plugin css-loader
```

```javascript
// config/webpack.config.js
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader']
      }
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: production ? '[name]-[contenthash].digested.css' : '[name].css'
    })
  ]
};
```

```erb
<!-- In your layout -->
<%= stylesheet_link_tag *webpack_asset_paths("application", extension: "css") %>
```

## Testing

### Browser Tests

In your test environment, compile assets before running tests:

```ruby
# config/environments/test.rb
config.webpack.dev_server.enabled = !ENV['CI']
```

```bash
# In CI
NODE_ENV=production rake webpack:compile
rspec
```

### With Webpack Dev Server

For faster feedback during development:

```ruby
# spec/rails_helper.rb or test/test_helper.rb
# Ensure webpack-dev-server is running before browser tests
```

## Deployment

### Capistrano

Add to your `Capfile`:

```ruby
require 'capistrano/webpack'
```

This automatically:
- Runs `webpack:compile` after `deploy:updated`
- Compiles assets with production settings
- Integrates with Rails asset pipeline tasks

### Heroku

Add a `package.json` build script:

```json
{
  "scripts": {
    "build": "webpack --config config/webpack.config.js --mode production"
  }
}
```

Heroku will automatically run `npm install` and the build script.

### Docker

```dockerfile
# Dockerfile
FROM ruby:3.2

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get install -y nodejs

# Copy application
WORKDIR /app
COPY Gemfile* ./
RUN bundle install

COPY package*.json ./
RUN npm install

COPY . .

# Compile assets
RUN RAILS_ENV=production rake webpack:compile
RUN RAILS_ENV=production rake assets:precompile

CMD ["rails", "server", "-b", "0.0.0.0"]
```

## Advanced Usage

### Dynamic Imports (Code Splitting)

Webpack 5 supports dynamic imports for code splitting:

```javascript
// webpack/application.js
document.getElementById('load-admin').addEventListener('click', async () => {
  const { AdminPanel } = await import('./admin_panel');
  new AdminPanel().render();
});
```

Webpack will automatically create a separate chunk file with the `.digested` extension.

### Source Maps

Source maps are automatically generated in development:

```javascript
// config/webpack.config.js
module.exports = {
  devtool: production ? 'source-map' : 'eval-source-map'
};
```

Propshaft will serve the `.map` files alongside your bundles.

### Tree Shaking

Webpack 5's production mode automatically enables tree shaking:

```javascript
// Only the used export will be included in the bundle
import { usedFunction } from './utils';
usedFunction();
```

## Migrating from Older Versions

### From Webpack 3/4

1. Update `package.json` dependencies to Webpack 5
2. Replace `webpack-manifest-plugin` v1 with v5: `const { WebpackManifestPlugin } = require('webpack-manifest-plugin')`
3. Update deprecated plugin names (e.g., `UglifyJsPlugin` → built-in optimization)
4. Add `.digested` to output filename patterns

### From Sprockets

1. Install `rs-webpack-rails` gem
2. Run generator: `rails generate webpack_rails:install`
3. Move JavaScript files from `app/assets/javascripts` to `webpack/`
4. Update requires to ES6 imports
5. Update view helpers from `javascript_include_tag 'application'` to `javascript_include_tag *webpack_asset_paths('application')`

## Troubleshooting

### Assets not found in production

Ensure you've run `rake webpack:compile` before deploying:

```bash
RAILS_ENV=production NODE_ENV=production rake webpack:compile
```

### Webpack dev server connection refused

Check that webpack-dev-server is running on port 3808:

```bash
npm run dev
# or
foreman start
```

### CORS errors in development

Ensure your webpack config has CORS headers:

```javascript
devServer: {
  headers: { 'Access-Control-Allow-Origin': '*' }
}
```

### Assets work in dev but not production

Verify the `.digested` extension in your webpack output config:

```javascript
filename: production ? '[name]-[contenthash].digested.js' : '[name].js'
```

### Propshaft not finding webpack assets

Ensure `public/webpack/` exists and the railtie is loading:

```bash
# Check if path is added to asset paths
rails console
> Rails.application.config.assets.paths rescue "Propshaft doesn't use config.assets"
```

## Configuration Reference

### Rails Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `config.webpack.config_file` | `'config/webpack.config.js'` | Webpack config file path |
| `config.webpack.binary` | `'node_modules/.bin/webpack'` | Webpack binary location |
| `config.webpack.output_dir` | `'public/webpack'` | Where webpack writes files |
| `config.webpack.public_path` | `'webpack'` | URL path prefix |
| `config.webpack.dev_server.enabled` | `Rails.env.development?` | Enable dev server |
| `config.webpack.dev_server.port` | `3808` | Dev server port |
| `config.webpack.dev_server.host` | `proc { request.host }` | Dev server host (dynamic) |

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure tests pass (`bundle exec rspec`)
5. Commit your changes (`git commit -am 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Testing

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/webpack/rails/helper_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

## License

MIT License. See [MIT-LICENSE](MIT-LICENSE) for details.

## Credits

- Original webpack-rails gem by [Michael Pearson](https://github.com/mipearson)
- Maintained by [glebtv](https://github.com/glebtv)
- Rails 7/8 + Propshaft modernization

## Links

- **Repository**: https://gitlab.com/rocket-science/webpack-rails
- **Issues**: https://gitlab.com/rocket-science/webpack-rails/issues
- **Webpack Documentation**: https://webpack.js.org
- **Rails Guides**: https://guides.rubyonrails.org
- **Propshaft**: https://github.com/rails/propshaft
