require 'json'
require 'pathname'

module Webpack
  module Rails
    # Injects webpack manifest entries into Propshaft's manifest at Rails boot time
    #
    # This allows Propshaft to resolve webpack assets by their logical names
    # (e.g., "npm.js" -> "npm-abc123.digested.js")
    class ManifestInjector
      # Called from webpack railtie after Rails initialization
      def self.inject(app)
        return unless app.respond_to?(:assets)

        # Try to require propshaft if not already loaded
        unless defined?(Propshaft::Assembly)
          begin
            require 'propshaft'
          rescue LoadError
            # Propshaft not available, skip injection
            return
          end
        end

        return unless defined?(Propshaft::Assembly)
        return unless app.assets
        return unless app.assets.is_a?(Propshaft::Assembly)

        webpack_manifest_path = get_webpack_manifest_path(app)
        return unless webpack_manifest_path.exist?

        webpack_data = load_webpack_manifest(webpack_manifest_path)
        return if webpack_data.nil? || webpack_data.empty?

        resolver = app.assets.resolver
        case resolver
        when Propshaft::Resolver::Static
          inject_into_static_resolver(resolver, webpack_data)
        when Propshaft::Resolver::Dynamic
          # In development mode, webpack assets are found via filesystem
          # The load_path already includes public/webpack via railtie
          # So no injection needed - they'll be discovered dynamically
          ::Rails.logger.debug("Webpack manifest injection skipped in development mode (Dynamic resolver)")
        else
          ::Rails.logger.warn("Unknown Propshaft resolver type: #{resolver.class}")
        end
      rescue => e
        ::Rails.logger.warn("Webpack manifest injection failed: #{e.message}")
        ::Rails.logger.debug(e.backtrace.join("\n"))
        # Don't fail hard - let app boot without webpack assets if needed
      end

      private

      def self.get_webpack_manifest_path(app)
        Pathname.new(File.join(
          app.root,
          app.config.webpack.output_dir,
          app.config.webpack.manifest_filename
        ))
      end

      def self.load_webpack_manifest(path)
        JSON.parse(File.read(path))
      rescue => e
        ::Rails.logger.warn("Failed to parse webpack manifest at #{path}: #{e.message}")
        nil
      end

      # For Static resolver: inject directly into in-memory manifest
      def self.inject_into_static_resolver(resolver, webpack_data)
        # Access the internal manifest (lazy-loaded)
        # We need to force the lazy load first by calling the private method
        manifest = resolver.send(:manifest)

        # Inject webpack entries
        inject_entries(manifest, webpack_data)

        ::Rails.logger.info("Injected #{webpack_data.size} webpack manifest entries into Propshaft")
      end

      def self.inject_entries(manifest, webpack_data)
        webpack_data.each do |logical_path, digested_path|
          # Webpack manifest format is simple: {"npm.js": "npm-abc123.digested.js"}
          # We need to create ManifestEntry objects and add them to the manifest

          entry = Propshaft::Manifest::ManifestEntry.new(
            logical_path: logical_path,
            digested_path: digested_path,
            integrity: nil # Webpack doesn't generate integrity hashes
          )

          # Add to manifest using the public push method
          manifest.push(entry)
        end
      end
    end
  end
end
