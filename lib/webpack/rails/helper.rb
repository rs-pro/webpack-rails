require 'action_view'
require 'json'

module Webpack
  module Rails
    # Asset path helpers for use with webpack
    module Helper
      # Return asset paths for a particular webpack entry point.
      #
      # Webpack assets are already compiled and digested, and they're served
      # directly from /webpack/, NOT through Propshaft's /assets/ prefix.
      #
      # This helper reads the webpack manifest.json directly and returns the
      # paths as-is (e.g., "/webpack/application-abc123.digested.js").
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
          # Read webpack manifest directly to get the actual path
          path = read_webpack_manifest[logical_path]

          if path.nil?
            raise "Webpack asset not found: #{logical_path}"
          end

          [path]
        rescue => e
          raise e unless ignore_missing
          [""]
        end
      end

      private

      def read_webpack_manifest
        @webpack_manifest ||= begin
          manifest_path = ::Rails.root.join(
            ::Rails.configuration.webpack.output_dir,
            ::Rails.configuration.webpack.manifest_filename
          )

          if File.exist?(manifest_path)
            JSON.parse(File.read(manifest_path))
          else
            {}
          end
        end
      end
    end
  end
end
