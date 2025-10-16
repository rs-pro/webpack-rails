# Load webpack tasks for Capistrano 3
#
# Add to Capfile:
#   require 'capistrano/webpack'
#
# This will add webpack:compile to the deployment flow, similar to assets:precompile

load File.expand_path("../tasks/webpack.rake", __FILE__)

# Capistrano 3 task hooks
namespace :load do
  task :defaults do
    set :webpack_roles, fetch(:webpack_roles, :web)
    set :webpack_env, fetch(:webpack_env, 'production')
  end
end

namespace :webpack do
  desc 'Compile webpack bundles'
  task :compile do
    on roles fetch(:webpack_roles) do
      within release_path do
        # Build environment variables for the rake task
        env_vars = {
          rails_env: fetch(:webpack_env),
          node_env: fetch(:webpack_env)
        }

        # Pass NVM wrapper path if capistrano-nvm is being used
        # The nvm_prefix is set by capistrano-nvm and contains the path to nvm-exec.sh
        if fetch(:nvm_prefix, nil)
          env_vars[:nvm_wrapper_path] = fetch(:nvm_prefix)
        end

        with env_vars do
          execute :rake, 'webpack:compile'
        end
      end
    end
  end

  desc 'Clobber webpack bundles'
  task :clobber do
    on roles fetch(:webpack_roles) do
      within release_path do
        with rails_env: fetch(:webpack_env) do
          execute :rake, 'webpack:clobber'
        end
      end
    end
  end
end

# Note: The hooks are registered in tasks/webpack.rake to avoid duplication
# The comprehensive implementation with manifest backup/restore is used there