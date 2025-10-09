require 'action_view'

module Webpack
  module Rails
    # Asset path helpers for use with webpack
    module Helper
      # Return asset paths for a particular webpack entry point.
      #
      # With propshaft integration, this helper now wraps propshaft's asset_path
      # to provide backwards compatibility. Assets are resolved through propshaft's
      # manifest, which includes webpack-built assets from public/webpack/.
      #
      # For webpack assets with .digested extension, propshaft will preserve the
      # webpack-generated digest and serve them correctly.
      #
      # Returns an array of asset paths for compatibility with legacy usage:
      #   <%= javascript_include_tag *webpack_asset_paths("application") %>
      #
      # Will raise an error if the entry point does not exist and ignore_missing is false.
      def webpack_asset_paths(source, extension: nil, ignore_missing: false)
        return [""] unless source.present?

        extension ||= "js"
        logical_path = "#{source}.#{extension}"

        begin
          # Use propshaft's asset_path helper to resolve the asset
          # This returns the digested path like /assets/application-abc123.digested.js
          path = asset_path(logical_path)
          [path]
        rescue => e
          raise e unless ignore_missing
          [""]
        end
      end
    end
  end
end
