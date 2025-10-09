# Webpack Rails Dummy Application

This is a Rails 8 dummy application used for testing the webpack-rails gem.

## Setup

1. Install dependencies:
   ```bash
   bundle install
   npm install
   ```

2. Build webpack assets:
   ```bash
   npm run build
   ```

3. Start the Rails server:
   ```bash
   rails server
   ```

4. Visit http://localhost:3000

## Development

To watch for webpack changes during development:
```bash
npm run watch
```

Or use the webpack dev server:
```bash
npm run dev
```

## Testing

This dummy app is used to test the webpack-rails gem integration with Rails 8 and Propshaft.

The application demonstrates:
- Webpack 5 integration with Rails 8
- Propshaft asset pipeline integration
- Using `webpack_asset_paths` helper in views
- Webpack assets with `.digested` extension
- Manifest-based asset resolution
