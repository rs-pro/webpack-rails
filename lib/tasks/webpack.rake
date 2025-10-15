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

    # Check for NVM wrapper (created by Capistrano during deployment)
    nvm_wrapper = "/tmp/#{Rails.application.class.module_parent_name.underscore}/nvm-exec.sh"

    if File.exist?(nvm_wrapper)
      # Production deployment - use NVM wrapper to ensure correct Node.js version
      sh "#{nvm_wrapper} #{webpack_bin} --config #{config_file} --bail"
    else
      # Local development or non-NVM environments
      sh "#{webpack_bin} --config #{config_file} --bail"
    end
  end
end
