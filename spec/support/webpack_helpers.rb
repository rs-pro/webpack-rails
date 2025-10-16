# Spec helpers for webpack-rails testing

module WebpackHelpers
  # Create a test webpack asset with optional content
  def create_webpack_asset(filename, content = nil)
    webpack_dir = Rails.root.join('public/webpack')
    FileUtils.mkdir_p(webpack_dir)

    content ||= case File.extname(filename)
                when '.js'
                  "console.log('test asset: #{filename}');"
                when '.css'
                  "/* test asset: #{filename} */ body { margin: 0; }"
                else
                  "test content"
                end

    File.write(webpack_dir.join(filename), content)
  end

  # Clean up webpack test assets
  # Preserves real webpack-compiled assets (those with .digested extension and manifest.json)
  def cleanup_webpack_assets
    webpack_dir = Rails.root.join('public/webpack')
    return unless webpack_dir.exist?

    Dir.glob(webpack_dir.join('*')).each do |file|
      next unless File.file?(file)
      basename = File.basename(file)

      # Preserve real webpack assets: manifest.json and .digested.* files
      next if basename == 'manifest.json'
      next if basename.include?('.digested.')

      # Delete test-generated files
      File.delete(file)
    end
  end

  # Simulate webpack compilation
  def simulate_webpack_compile(entry_name, options = {})
    extension = options[:extension] || 'js'
    hash = options[:hash] || SecureRandom.hex(8)
    content = options[:content]

    filename = "#{entry_name}-#{hash}.digested.#{extension}"
    create_webpack_asset(filename, content)

    filename
  end

  # Create webpack manifest.json
  def create_webpack_manifest(entries)
    webpack_dir = Rails.root.join('public/webpack')
    FileUtils.mkdir_p(webpack_dir)

    manifest = {
      errors: [],
      assetsByChunkName: entries
    }

    File.write(
      webpack_dir.join('manifest.json'),
      JSON.pretty_generate(manifest)
    )
  end
end

RSpec.configure do |config|
  config.include WebpackHelpers

  # Clean up webpack assets after each test
  config.after(:each) do
    cleanup_webpack_assets if defined?(cleanup_webpack_assets)
  end
end
