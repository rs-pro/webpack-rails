# Webpack Rails Dummy App - Quick Setup Guide

## Overview
This is a minimal Rails 8 application configured to test the webpack-rails gem with Propshaft integration.

## Key Files

### Configuration Files

**config/application.rb**
- Loads the webpack-rails gem from `../../../lib`
- Configures webpack settings (output_dir, manifest_filename, dev_server)
- Sets up Rails 8 defaults with Propshaft

**config/webpack.config.js**
- Webpack 5 configuration
- Entry point: `webpack/application.js`
- Output: `public/webpack/[name]-[contenthash].digested.js`
- Uses `.digested` extension to prevent Propshaft from re-digesting

**package.json**
- Webpack 5 dependencies
- Scripts: `build`, `dev`, `watch`

### Application Files

**app/views/layouts/application.html.erb**
```erb
<%= javascript_include_tag *webpack_asset_paths("application") %>
```
This demonstrates the webpack_asset_paths helper integration.

**webpack/application.js**
Simple JavaScript that modifies the DOM to verify webpack is working.

## Setup Steps

```bash
# 1. Install Ruby dependencies (from gem root)
cd /data/webpack-rails
bundle install

# 2. Install Node dependencies
cd spec/dummy
npm install

# 3. Build webpack assets
npm run build

# 4. Start Rails server
bin/rails server

# 5. Visit http://localhost:3000
```

## Development Workflow

### Watch mode (rebuilds on changes)
```bash
npm run watch
```

### Webpack dev server (hot reload)
```bash
npm run dev
```

### Production build
```bash
NODE_ENV=production npm run build
```

## Testing the Integration

1. After building webpack assets, check `public/webpack/` for:
   - `application-[hash].digested.js`
   - `manifest.json`

2. Start the Rails server and visit the root page

3. Check the browser console for: "Webpack is loaded and working!"

4. The page should show green text saying "Success! JavaScript from webpack has modified this content."

## File Structure
```
spec/dummy/
├── app/
│   ├── controllers/pages_controller.rb
│   └── views/
│       ├── layouts/application.html.erb  # Uses webpack_asset_paths
│       └── pages/index.html.erb
├── config/
│   ├── application.rb                    # Gem configuration
│   └── webpack.config.js                 # Webpack config
├── webpack/
│   └── application.js                    # Entry point
├── public/webpack/                       # Build output
└── package.json                          # NPM dependencies
```

## What This Tests

- Webpack 5 integration with Rails 8
- Propshaft asset pipeline integration
- `webpack_asset_paths` helper functionality
- `.digested` extension handling
- Manifest-based asset resolution
- Development and production builds

## Troubleshooting

**Assets not loading?**
1. Run `npm run build` first
2. Check `public/webpack/manifest.json` exists
3. Verify the helper is called correctly in the layout

**Webpack build fails?**
1. Ensure Node.js and npm are installed
2. Run `npm install` again
3. Check for syntax errors in webpack.config.js

**Rails server won't start?**
1. Run `bundle install` from the gem root
2. Ensure SQLite3 is installed
3. Check `config/application.rb` for errors
