require 'rails_helper'

RSpec.describe Webpack::Rails::Helper, type: :helper do
  describe '#webpack_asset_paths' do
    let(:source) { 'application' }

    context 'with propshaft integration' do
      before do
        # Mock propshaft's asset_path helper
        allow(helper).to receive(:asset_path).and_call_original
      end

      it 'returns an array' do
        # Mock asset_path to return a test path
        allow(helper).to receive(:asset_path).with('application.js')
          .and_return('/assets/application-abc123.digested.js')

        result = helper.webpack_asset_paths('application')
        expect(result).to be_an(Array)
      end

      it 'returns array with one element for single asset' do
        allow(helper).to receive(:asset_path).with('application.js')
          .and_return('/assets/application-abc123.digested.js')

        result = helper.webpack_asset_paths('application')
        expect(result.length).to eq(1)
        expect(result.first).to eq('/assets/application-abc123.digested.js')
      end

      context 'with different extensions' do
        it 'handles .js extension' do
          allow(helper).to receive(:asset_path).with('application.js')
            .and_return('/assets/application-abc123.digested.js')

          result = helper.webpack_asset_paths('application', extension: 'js')
          expect(result.first).to include('.js')
        end

        it 'handles .css extension' do
          allow(helper).to receive(:asset_path).with('styles.css')
            .and_return('/assets/styles-def456.digested.css')

          result = helper.webpack_asset_paths('styles', extension: 'css')
          expect(result.first).to include('.css')
        end

        it 'defaults to .js extension when not specified' do
          allow(helper).to receive(:asset_path).with('application.js')
            .and_return('/assets/application-abc123.digested.js')

          result = helper.webpack_asset_paths('application')
          expect(result.first).to include('.js')
        end
      end

      context 'with ignore_missing flag' do
        it 'raises error when asset not found and ignore_missing is false' do
          allow(helper).to receive(:asset_path).with('missing.js')
            .and_raise(StandardError.new("Asset not found"))

          expect {
            helper.webpack_asset_paths('missing', ignore_missing: false)
          }.to raise_error(StandardError)
        end

        it 'returns empty string when asset not found and ignore_missing is true' do
          allow(helper).to receive(:asset_path).with('missing.js')
            .and_raise(StandardError.new("Asset not found"))

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

      context 'propshaft asset_path integration' do
        it 'uses propshaft asset_path helper' do
          expect(helper).to receive(:asset_path).with('application.js')
            .and_return('/assets/application-abc123.digested.js')

          helper.webpack_asset_paths('application')
        end

        it 'preserves digested extension from webpack' do
          allow(helper).to receive(:asset_path).with('bundle.js')
            .and_return('/assets/bundle-xyz789.digested.js')

          result = helper.webpack_asset_paths('bundle')
          expect(result.first).to include('.digested.js')
        end

        it 'handles propshaft manifest resolution' do
          # Simulate propshaft finding a digested webpack asset
          allow(helper).to receive(:asset_path).with('main.js')
            .and_return('/assets/main-hash123.digested.js')

          result = helper.webpack_asset_paths('main')
          expect(result.first).to match(/main-\w+\.digested\.js/)
        end
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
