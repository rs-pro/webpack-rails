namespace :webpack do
  desc "Compile webpack bundles"
  task compile: :environment do
    ENV["TARGET"] = 'production' # TODO: Deprecated, use NODE_ENV instead
    ENV["NODE_ENV"] ||= 'production'
    webpack_bin = ::Rails.root.join(::Rails.configuration.webpack.binary)
    config_file = ::Rails.root.join(::Rails.configuration.webpack.config_file)

    unless File.exist?(webpack_bin)
      raise "Can't find our webpack executable at #{webpack_bin} - have you run `npm install`?"
    end

    unless File.exist?(config_file)
      raise "Can't find our webpack config file at #{config_file}"
    end

    # Check for NVM wrapper path from environment variable
    # This should be set by capistrano-nvm or deployment scripts
    # Example: NVM_WRAPPER_PATH=/tmp/myapp/nvm-exec.sh
    nvm_wrapper = ENV['NVM_WRAPPER_PATH']

    if nvm_wrapper && File.exist?(nvm_wrapper)
      # Use NVM wrapper if explicitly configured and exists
      puts "Using NVM wrapper: #{nvm_wrapper}"
      sh "#{nvm_wrapper} #{webpack_bin} --config #{config_file} --bail"
    else
      # Direct execution (local development or non-NVM deployments)
      sh "#{webpack_bin} --config #{config_file} --bail"
    end
  end
end