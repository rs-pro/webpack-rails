#!/bin/bash
# Helper script to add gem to Gemfile in CI
set -e

echo "gem 'rs-webpack-rails', path: '${CI_PROJECT_DIR}'" >> Gemfile
echo "Added rs-webpack-rails gem to Gemfile"
