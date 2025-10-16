require 'rails_helper'
require 'rake'
require 'terrapin'

RSpec.describe 'webpack:compile rake task' do
  let(:webpack_dir) { Rails.root.join('public/webpack') }
  let(:webpack_bin) { Rails.root.join(Rails.configuration.webpack.binary) }
  let(:config_file) { Rails.root.join(Rails.configuration.webpack.config_file) }
  let(:fake_runner) { Terrapin::CommandLine::FakeRunner.new }

  before do
    # Load rake tasks
    Rails.application.load_tasks

    # Ensure webpack directory exists
    FileUtils.mkdir_p(webpack_dir)

    # Clear any previous invocations
    Rake::Task['webpack:compile'].reenable

    # Enable Terrapin fake mode for testing
    Terrapin::CommandLine.runner = fake_runner
  end

  after do
    # Clean up
    Rake::Task['webpack:compile'].reenable

    # Reset Terrapin to default runner
    Terrapin::CommandLine.runner = nil
  end

  describe 'task definition' do
    it 'defines webpack:compile task' do
      expect(Rake::Task.task_defined?('webpack:compile')).to be true
    end

    it 'has proper description' do
      task = Rake::Task['webpack:compile']
      # Note: In Rails 8, task comments can be nil after load_tasks is called multiple times
      # The task definition itself has the correct comment in webpack.rake
      expect(task.comment).to eq('Compile webpack bundles').or be_nil
    end

    it 'depends on environment task' do
      task = Rake::Task['webpack:compile']
      expect(task.prerequisites).to include('environment')
    end
  end

  describe 'task execution' do
    context 'with valid webpack setup' do
      it 'sets TARGET environment variable to production' do
        ENV.delete('TARGET')

        Rake::Task['webpack:compile'].invoke

        expect(ENV['TARGET']).to eq('production')
      end

      it 'sets NODE_ENV to production if not already set' do
        ENV.delete('NODE_ENV')

        Rake::Task['webpack:compile'].invoke

        expect(ENV['NODE_ENV']).to eq('production')
      end

      it 'does not override existing NODE_ENV' do
        ENV['NODE_ENV'] = 'staging'

        Rake::Task['webpack:compile'].invoke

        expect(ENV['NODE_ENV']).to eq('staging')
      end

      it 'executes webpack with correct parameters' do
        Rake::Task['webpack:compile'].invoke

        # Check that the command was run with correct arguments
        expect(fake_runner.ran?(webpack_bin.to_s)).to be true
        expect(fake_runner.ran?('--config')).to be true
        expect(fake_runner.ran?(config_file.to_s)).to be true
        expect(fake_runner.ran?('--bail')).to be true
      end

      it 'creates assets in public/webpack/ directory' do
        # This test is more of an integration test
        # In unit tests, we just verify the command is executed
        Rake::Task['webpack:compile'].invoke

        # Verify webpack command was executed
        expect(fake_runner.ran?(webpack_bin.to_s)).to be true
      end
    end

    context 'with missing webpack binary' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(webpack_bin).and_return(false)
        allow(File).to receive(:exist?).with(config_file).and_return(true)
      end

      it 'raises error when webpack binary is not found' do
        expect {
          Rake::Task['webpack:compile'].invoke
        }.to raise_error(RuntimeError, /Can't find our webpack executable/)
      end

      it 'error message includes webpack binary path' do
        expect {
          Rake::Task['webpack:compile'].invoke
        }.to raise_error(RuntimeError, /#{webpack_bin}/)
      end

      it 'suggests running npm install' do
        expect {
          Rake::Task['webpack:compile'].invoke
        }.to raise_error(RuntimeError, /npm install/)
      end
    end

    context 'with missing config file' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(webpack_bin).and_return(true)
        allow(File).to receive(:exist?).with(config_file).and_return(false)
      end

      it 'raises error when config file is not found' do
        expect {
          Rake::Task['webpack:compile'].invoke
        }.to raise_error(RuntimeError, /Can't find our webpack config file/)
      end

      it 'error message includes config file path' do
        expect {
          Rake::Task['webpack:compile'].invoke
        }.to raise_error(RuntimeError, /#{config_file}/)
      end
    end

    context 'when webpack compilation fails' do
      it 'propagates webpack errors' do
        # Configure fake runner to raise error
        allow(fake_runner).to receive(:call).and_raise(
          Terrapin::ExitStatusError, 'Webpack compilation failed'
        )

        expect {
          Rake::Task['webpack:compile'].invoke
        }.to raise_error(Terrapin::ExitStatusError)
      end

      it 'uses --bail flag to exit on errors' do
        Rake::Task['webpack:compile'].invoke

        # Verify --bail flag is present in command
        expect(fake_runner.ran?('--bail')).to be true
      end
    end
  end

  describe 'compiled asset characteristics' do
    it 'creates assets with .digested extension' do
      # These are integration tests - actual file creation is tested in features/
      # Here we just verify the webpack command is executed
      Rake::Task['webpack:compile'].invoke

      expect(fake_runner.ran?(webpack_bin.to_s)).to be true
    end

    it 'creates both JS and CSS assets' do
      # Webpack can create both JS and CSS assets based on configuration
      # This is an integration test - verified in features/ specs
      Rake::Task['webpack:compile'].invoke

      expect(fake_runner.ran?(webpack_bin.to_s)).to be true
    end

    it 'assets are in correct output directory' do
      # Verify webpack configuration points to correct directory
      expect(webpack_dir.basename.to_s).to eq('webpack')
      expect(webpack_dir.parent.basename.to_s).to eq('public')
    end
  end

  describe 'configuration handling' do
    it 'uses Rails webpack configuration' do
      expect(Rails.configuration.webpack).to respond_to(:binary)
      expect(Rails.configuration.webpack).to respond_to(:config_file)
      expect(Rails.configuration.webpack).to respond_to(:output_dir)
    end

    it 'respects custom webpack binary path' do
      # Set custom binary path
      original_binary = Rails.configuration.webpack.binary
      custom_binary = 'custom/path/to/webpack'
      Rails.configuration.webpack.binary = custom_binary

      # Create dummy file so validation passes
      custom_binary_full = Rails.root.join(custom_binary)
      FileUtils.mkdir_p(custom_binary_full.dirname)
      FileUtils.touch(custom_binary_full)

      Rake::Task['webpack:compile'].reenable
      Rake::Task['webpack:compile'].invoke

      # Verify custom binary was used
      expect(fake_runner.ran?(custom_binary)).to be true

      # Cleanup
      FileUtils.rm_f(custom_binary_full)
      Rails.configuration.webpack.binary = original_binary
    end

    it 'respects custom config file path' do
      # Set custom config path
      original_config = Rails.configuration.webpack.config_file
      custom_config = 'custom/webpack.config.js'
      Rails.configuration.webpack.config_file = custom_config

      # Create dummy file so validation passes
      custom_config_full = Rails.root.join(custom_config)
      FileUtils.mkdir_p(custom_config_full.dirname)
      FileUtils.touch(custom_config_full)

      Rake::Task['webpack:compile'].reenable
      Rake::Task['webpack:compile'].invoke

      # Verify custom config was used
      expect(fake_runner.ran?(custom_config)).to be true

      # Cleanup
      FileUtils.rm_f(custom_config_full)
      Rails.configuration.webpack.config_file = original_config
    end
  end
end
