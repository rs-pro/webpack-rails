require 'rails_helper'

RSpec.describe Webpack::Rails::Helper, type: :helper do
  describe '#webpack_asset_paths' do
    let(:source) { 'application' }

    context 'with webpack manifest' do
      let(:webpack_manifest) do
        {
          'application.js' => '/webpack/application-abc123.digested.js',
          'styles.css' => '/webpack/styles-def456.digested.css',
          'bundle.js' => '/webpack/bundle-xyz789.digested.js',
          'main.js' => '/webpack/main-hash123.digested.js'
        }
      end

      before do
        # Mock reading the webpack manifest
        allow(helper).to receive(:read_webpack_manifest).and_return(webpack_manifest)
      end

      it 'returns an array' do
        result = helper.webpack_asset_paths('application')
        expect(result).to be_an(Array)
      end

      it 'returns array with one element for single asset' do
        result = helper.webpack_asset_paths('application')
        expect(result.length).to eq(1)
        expect(result.first).to eq('/webpack/application-abc123.digested.js')
      end

      context 'with different extensions' do
        it 'handles .js extension' do
          result = helper.webpack_asset_paths('application', extension: 'js')
          expect(result.first).to include('.js')
          expect(result.first).to eq('/webpack/application-abc123.digested.js')
        end

        it 'handles .css extension' do
          result = helper.webpack_asset_paths('styles', extension: 'css')
          expect(result.first).to include('.css')
          expect(result.first).to eq('/webpack/styles-def456.digested.css')
        end

        it 'defaults to .js extension when not specified' do
          result = helper.webpack_asset_paths('application')
          expect(result.first).to include('.js')
          expect(result.first).to eq('/webpack/application-abc123.digested.js')
        end
      end

      context 'with ignore_missing flag' do
        it 'raises error when asset not found and ignore_missing is false' do
          expect {
            helper.webpack_asset_paths('missing', ignore_missing: false)
          }.to raise_error(/Webpack asset not found: missing\.js/)
        end

        it 'returns empty string when asset not found and ignore_missing is true' do
          result = helper.webpack_asset_paths('missing', ignore_missing: true)
          expect(result).to eq([''])
        end
      end

      context 'with empty source' do
        it 'returns empty string array when source is nil' do
          result = helper.webpack_asset_paths(nil)
          expect(result).to eq([''])
        end

        it 'returns empty string array when source is empty string' do
          result = helper.webpack_asset_paths('')
          expect(result).to eq([''])
        end

        it 'returns empty string array when source is blank' do
          result = helper.webpack_asset_paths('  ')
          expect(result).to eq([''])
        end
      end

      context 'webpack manifest integration' do
        it 'reads webpack manifest directly (not through propshaft)' do
          # Should read from webpack manifest, not call asset_path
          expect(helper).not_to receive(:asset_path)

          result = helper.webpack_asset_paths('application')
          expect(result.first).to eq('/webpack/application-abc123.digested.js')
        end

        it 'preserves digested extension from webpack' do
          result = helper.webpack_asset_paths('bundle')
          expect(result.first).to include('.digested.js')
          expect(result.first).to eq('/webpack/bundle-xyz789.digested.js')
        end

        it 'handles webpack manifest resolution' do
          result = helper.webpack_asset_paths('main')
          expect(result.first).to match(/\/webpack\/main-\w+\.digested\.js/)
          expect(result.first).to eq('/webpack/main-hash123.digested.js')
        end
      end
    end

    context 'webpack asset paths should use /webpack/ not /assets/webpack/' do
      it 'returns /webpack/ paths directly from manifest, not /assets/webpack/' do
        # Webpack assets are already compiled with their own digest
        # and should be served from /webpack/, not through Propshaft's /assets/
        webpack_manifest = {
          'application.js' => '/webpack/application-5db02e5421fdaadda0c8.digested.js'
        }

        # Mock the private read_webpack_manifest method
        allow(helper).to receive(:read_webpack_manifest).and_return(webpack_manifest)

        result = helper.webpack_asset_paths('application')

        # Should return /webpack/ path directly (not /assets/webpack/)
        expect(result.first).to eq('/webpack/application-5db02e5421fdaadda0c8.digested.js')
        expect(result.first).not_to start_with('/assets/webpack/')
      end

      it 'reads webpack manifest from configured location' do
        webpack_manifest = {
          'bundle.js' => '/webpack/bundle-xyz789.digested.js',
          'styles.css' => '/webpack/styles-abc456.digested.css'
        }

        allow(helper).to receive(:read_webpack_manifest).and_return(webpack_manifest)

        js_result = helper.webpack_asset_paths('bundle', extension: 'js')
        css_result = helper.webpack_asset_paths('styles', extension: 'css')

        expect(js_result.first).to eq('/webpack/bundle-xyz789.digested.js')
        expect(css_result.first).to eq('/webpack/styles-abc456.digested.css')
      end
    end

    context 'with actual propshaft helper' do
      it 'can resolve webpack assets through propshaft' do
        skip "Requires Propshaft assembly initialized - see ManifestInjector specs for integration tests"

        # This would require actual assets to be present
        # and propshaft to be properly configured
        expect {
          helper.webpack_asset_paths('application')
        }.not_to raise_error
      end
    end
  end
end
