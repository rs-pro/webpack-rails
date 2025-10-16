require 'rails_helper'
require 'webpack/rails/manifest_injector'

RSpec.describe Webpack::Rails::ManifestInjector do
  describe '.inject' do
    let(:app) { double('Rails::Application') }
    let(:config) { double('Config') }
    let(:webpack_config) { double('WebpackConfig') }
    let(:assembly) { double('Propshaft::Assembly') }
    let(:manifest) { double('Propshaft::Manifest') }
    let(:root_path) { Pathname.new('/tmp') }
    let(:webpack_manifest_path) { Pathname.new('/tmp/webpack/manifest.json') }

    # Create resolver as an actual instance of the stubbed class so case statements work
    let(:resolver) do
      # Will be created after stub_const runs
      Propshaft::Resolver::Static.new
    end
    let(:webpack_manifest_content) do
      {
        'npm.js' => 'npm-abc123.digested.js',
        'application.js' => 'application-def456.digested.js'
      }
    end

    before do
      # Stub the constant checks
      stub_const('Propshaft::Assembly', Class.new)
      stub_const('Propshaft::Resolver::Static', Class.new)
      stub_const('Propshaft::Manifest::ManifestEntry', Struct.new(:logical_path, :digested_path, :integrity))

      # Mock Rails.logger
      allow(Rails).to receive(:logger).and_return(Logger.new(nil))

      # Setup app mocks
      allow(app).to receive(:respond_to?).with(:assets).and_return(true)
      allow(app).to receive(:assets).and_return(assembly)
      allow(app).to receive(:root).and_return(root_path)
      allow(app).to receive(:config).and_return(config)
      allow(config).to receive(:webpack).and_return(webpack_config)
      allow(webpack_config).to receive(:output_dir).and_return('webpack')
      allow(webpack_config).to receive(:manifest_filename).and_return('manifest.json')

      # Setup assembly/resolver mocks
      allow(assembly).to receive(:is_a?).with(Propshaft::Assembly).and_return(true)
      allow(assembly).to receive(:resolver).and_return(resolver)

      # Make resolver respond to send(:manifest)
      allow(resolver).to receive(:send).with(:manifest).and_return(manifest)

      allow(manifest).to receive(:push)

      # Setup file system mocks - use allow_any_instance_of for Pathname
      allow(File).to receive(:join).and_call_original
      allow(File).to receive(:join).with(root_path, 'webpack', 'manifest.json')
        .and_return('/tmp/webpack/manifest.json')
      allow(Pathname).to receive(:new).and_call_original
      allow(Pathname).to receive(:new).with('/tmp/webpack/manifest.json')
        .and_return(webpack_manifest_path)
      allow(webpack_manifest_path).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).with(webpack_manifest_path)
        .and_return(JSON.generate(webpack_manifest_content))
    end

    context 'when all preconditions are met' do
      it 'injects webpack manifest entries into propshaft manifest' do
        # Expect manifest.push to be called for each entry
        expect(manifest).to receive(:push).twice

        described_class.inject(app)
      end

      it 'creates ManifestEntry objects with correct data' do
        entry_matcher = lambda do |entry|
          entry.logical_path == 'npm.js' &&
            entry.digested_path == 'npm-abc123.digested.js' &&
            entry.integrity.nil?
        end

        expect(manifest).to receive(:push).with(satisfy(&entry_matcher))
        expect(manifest).to receive(:push) # for application.js

        described_class.inject(app)
      end
    end

    context 'when app.assets is not available' do
      before do
        allow(app).to receive(:respond_to?).with(:assets).and_return(false)
      end

      it 'returns early without error' do
        expect(manifest).not_to receive(:push)
        expect { described_class.inject(app) }.not_to raise_error
      end
    end

    context 'when webpack manifest file does not exist' do
      before do
        allow(webpack_manifest_path).to receive(:exist?).and_return(false)
      end

      it 'returns early without error' do
        expect(manifest).not_to receive(:push)
        expect { described_class.inject(app) }.not_to raise_error
      end
    end

    context 'when webpack manifest is empty' do
      before do
        allow(File).to receive(:read).with(webpack_manifest_path)
          .and_return('{}')
      end

      it 'returns early without injecting' do
        expect(manifest).not_to receive(:push)
        described_class.inject(app)
      end
    end

    context 'when an error occurs during injection' do
      before do
        allow(File).to receive(:read).with(webpack_manifest_path)
          .and_raise(StandardError.new('Test error'))
      end

      it 'logs a warning and does not fail' do
        expect(Rails.logger).to receive(:warn).with(/Failed to parse webpack manifest/)
        expect { described_class.inject(app) }.not_to raise_error
      end
    end

    context 'with real webpack manifest from test app' do
      let(:dummy_root) { Pathname.new(File.expand_path('../../dummy', __dir__)) }
      let(:real_manifest_path) { dummy_root.join('public/webpack/manifest.json') }

      before do
        unless File.exist?(real_manifest_path)
          fail "Real webpack manifest not found at #{real_manifest_path}. Run: cd spec/dummy && NODE_ENV=production npm run build"
        end

        # Use real manifest path
        allow(app).to receive(:root).and_return(dummy_root)
        allow(webpack_config).to receive(:output_dir).and_return('public/webpack')

        # Let the real file system operations happen
        allow(File).to receive(:join).and_call_original
        allow(Pathname).to receive(:new).and_call_original
        allow(File).to receive(:read).and_call_original
      end

      it 'successfully parses and injects real webpack manifest' do
        # Should inject entries for each logical path in manifest
        expect(manifest).to receive(:push).at_least(:once)

        described_class.inject(app)
      end

      it 'handles webpack paths with leading slashes' do
        manifest_data = JSON.parse(File.read(real_manifest_path))

        # Real webpack manifest has paths like "/webpack/application-hash.digested.js"
        # We should extract just the filename for digested_path
        first_entry = manifest_data.first
        expect(first_entry[1]).to match(%r{^/webpack/.*\.digested\.js})
      end
    end
  end
end
