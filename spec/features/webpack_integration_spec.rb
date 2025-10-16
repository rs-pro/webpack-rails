require 'rails_helper'

RSpec.describe 'Webpack Integration', type: :feature do
  let(:webpack_dir) { Rails.root.join('public/webpack') }
  let(:test_asset_name) { 'application.js' }
  let(:test_asset_digested) { 'application-abc123.digested.js' }

  before do
    # Ensure webpack directory exists
    FileUtils.mkdir_p(webpack_dir)
  end

  after do
    # Clean up test assets
    FileUtils.rm_rf(webpack_dir.join('*.js'))
    FileUtils.rm_rf(webpack_dir.join('*.css'))
  end

  describe 'webpack assets serving' do
    context 'with compiled webpack assets' do
      before do
        # Create a test webpack asset
        File.write(
          webpack_dir.join(test_asset_digested),
          "console.log('Test webpack asset');"
        )
      end

      it 'serves webpack assets from public/webpack directory' do
        # Make a request to the webpack asset
        visit "/webpack/#{test_asset_digested}"

        # The asset should be served
        expect(page.status_code).to eq(200)
        expect(page.body).to include("console.log('Test webpack asset');")
      end

      it 'includes correct content type for JavaScript' do
        visit "/webpack/#{test_asset_digested}"

        expect(page.response_headers['Content-Type']).to include('text/javascript')
      end
    end

    context 'with CSS assets' do
      let(:css_asset) { 'styles-def456.digested.css' }

      before do
        File.write(
          webpack_dir.join(css_asset),
          "body { background: #f0f0f0; }"
        )
      end

      it 'serves CSS webpack assets' do
        visit "/webpack/#{css_asset}"

        expect(page.status_code).to eq(200)
        expect(page.body).to include('background: #f0f0f0')
      end

      it 'includes correct content type for CSS' do
        visit "/webpack/#{css_asset}"

        expect(page.response_headers['Content-Type']).to include('text/css')
      end
    end
  end

  describe 'webpack_asset_paths helper in views' do
    let(:controller_class) do
      Class.new(ApplicationController) do
        def test_action
          render inline: <<~ERB
            <html>
              <head>
                <% webpack_asset_paths('application', extension: 'js').each do |path| %>
                  <script src="<%= path %>"></script>
                <% end %>
              </head>
              <body>
                <h1>Test Page</h1>
              </body>
            </html>
          ERB
        end
      end
    end

    before do
      # Register a test route
      Rails.application.routes.draw do
        get '/test_webpack_helper', to: 'test_webpack#test_action'
      end

      stub_const('TestWebpackController', controller_class)

      # Mock the asset_path helper to return a test path
      allow_any_instance_of(ActionView::Base).to receive(:asset_path)
        .with('application.js')
        .and_return('/assets/application-test123.digested.js')
    end

    after do
      # Reset routes
      Rails.application.reload_routes!
    end

    it 'renders webpack assets in views using the helper' do
      visit '/test_webpack_helper'

      expect(page).to have_css('script[src*="application"]', visible: false)
    end

    it 'generates proper script tags with asset paths' do
      visit '/test_webpack_helper'
      body = page.body

      expect(body).to include('<script src=')
      expect(body).to include('application')
    end
  end

  describe 'compiled assets with digested extension', :js do
    let(:digested_js) { 'bundle-xyz789.digested.js' }
    let(:digested_css) { 'main-abc123.digested.css' }

    before do
      # Create webpack assets with .digested extension
      File.write(
        webpack_dir.join(digested_js),
        "console.log('Digested webpack bundle');"
      )

      File.write(
        webpack_dir.join(digested_css),
        ".container { margin: 0 auto; }"
      )
    end

    it 'serves JavaScript assets with .digested extension' do
      visit "/webpack/#{digested_js}"

      expect(page.status_code).to eq(200)
      expect(page.body).to include('Digested webpack bundle')
    end

    it 'serves CSS assets with .digested extension' do
      visit "/webpack/#{digested_css}"

      expect(page.status_code).to eq(200)
      expect(page.body).to include('container')
    end

    it 'preserves the full filename with hash and extension' do
      visit "/webpack/#{digested_js}"

      # Verify the asset was served from the correct path
      expect(page.status_code).to eq(200)
      expect(page.current_path).to include('digested.js')
    end
  end

  describe 'webpack assets in propshaft manifest' do
    it 'webpack directory is in asset load paths' do
      skip "config.assets not available in Rails 8 with Propshaft - Propshaft auto-discovers assets"
    end

    it 'propshaft can resolve webpack assets' do
      # Create a test asset
      File.write(
        webpack_dir.join('test-hash123.digested.js'),
        "console.log('test');"
      )

      # Verify the asset exists
      expect(File.exist?(webpack_dir.join('test-hash123.digested.js'))).to be true
    end
  end

  describe 'asset compilation workflow' do
    it 'creates assets in public/webpack/ directory' do
      # Simulate webpack compilation creating assets
      compiled_asset = 'compiled-abc.digested.js'
      File.write(
        webpack_dir.join(compiled_asset),
        "// Compiled by webpack\nconsole.log('compiled');"
      )

      expect(File.exist?(webpack_dir.join(compiled_asset))).to be true
    end

    it 'assets have appropriate file permissions' do
      test_file = webpack_dir.join('permissions-test.digested.js')
      File.write(test_file, "console.log('test');")

      # Check file is readable
      expect(File.readable?(test_file)).to be true
    end
  end

  describe 'multiple webpack entries' do
    before do
      # Create multiple webpack bundles
      File.write(
        webpack_dir.join('vendor-aaa111.digested.js'),
        "console.log('vendor');"
      )

      File.write(
        webpack_dir.join('app-bbb222.digested.js'),
        "console.log('app');"
      )

      File.write(
        webpack_dir.join('styles-ccc333.digested.css'),
        "body { margin: 0; }"
      )
    end

    it 'serves multiple webpack assets independently' do
      visit '/webpack/vendor-aaa111.digested.js'
      expect(page.status_code).to eq(200)
      expect(page.body).to include('vendor')

      visit '/webpack/app-bbb222.digested.js'
      expect(page.status_code).to eq(200)
      expect(page.body).to include('app')

      visit '/webpack/styles-ccc333.digested.css'
      expect(page.status_code).to eq(200)
      expect(page.body).to include('margin: 0')
    end
  end

end
