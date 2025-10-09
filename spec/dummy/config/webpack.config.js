// Webpack 5 configuration for Rails 8 with Propshaft integration
'use strict';

const path = require('path');
const { WebpackManifestPlugin } = require('webpack-manifest-plugin');

// must match config.webpack.dev_server.port
const devServerPort = 3808;
const host = process.env.WEBPACK_DEV_SERVER_HOST || 'localhost';

// set NODE_ENV=production on the environment to add asset fingerprints
const production = process.env.NODE_ENV === 'production';

const config = {
  mode: production ? 'production' : 'development',

  entry: {
    // Sources are expected to live in $app_root/webpack
    application: './webpack/application.js'
  },

  output: {
    // Build assets directly in to public/webpack/, let webpack know
    // that all webpacked assets start with webpack/

    // must match config.webpack.output_dir
    path: path.join(__dirname, '..', 'public', 'webpack'),
    publicPath: production ? '/webpack/' : `http://${host}:${devServerPort}/webpack/`,

    // Use .digested extension to signal propshaft that webpack already digested the file
    // This prevents propshaft from re-digesting webpack assets
    filename: production ? '[name]-[contenthash].digested.js' : '[name].js',
    chunkFilename: production ? '[name]-[contenthash].digested.chunk.js' : '[name].chunk.js',
  },

  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env']
          }
        }
      }
    ]
  },

  resolve: {
    modules: [
      path.resolve(__dirname, '..', 'webpack'),
      path.resolve(__dirname, '..', 'node_modules')
    ],
  },

  plugins: [
    // must match config.webpack.manifest_filename
    new WebpackManifestPlugin({
      publicPath: production ? '/webpack/' : `http://${host}:${devServerPort}/webpack/`,
      writeToFileEmit: true, // Write manifest even in dev server mode
    })
  ],

  devtool: production ? 'source-map' : 'eval-source-map',

  devServer: {
    port: devServerPort,
    host: host,
    hot: true,
    headers: { 'Access-Control-Allow-Origin': '*' },
    allowedHosts: 'all',
  },

  // Performance hints
  performance: {
    hints: production ? 'warning' : false
  }
};

module.exports = config;
