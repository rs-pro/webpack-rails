# based on https://github.com/capistrano/rails/blob/master/lib/capistrano/tasks/assets.rake

load File.expand_path("../set_rails_env.rake", __FILE__)

module Capistrano
  class FileNotFound < StandardError
  end
end

namespace :deploy do
  desc 'Normalize webpack asset timestamps'
  task :normalize_webpack_assets => [:set_rails_env] do
    on release_roles(fetch(:assets_roles)) do
      assets = Array(fetch(:normalize_asset_timestamps, []))
      if assets.any?
        within release_path do
          execute :find, "#{assets.join(' ')} -exec touch -t #{asset_timestamp} {} ';'; true"
        end
      end
    end
  end

  desc 'Compile webpack assets'
  task :compile_webpack_assets => [:webpack_set_rails_env] do
    invoke 'deploy:webpack:compile'
    invoke 'deploy:webpack:backup_manifest'
  end

  desc 'Rollback webpack assets'
  task :rollback_webpack_assets => [:set_rails_env] do
    begin
      invoke 'deploy:webpack:restore_manifest'
    rescue Capistrano::FileNotFound
      invoke 'deploy:compile_webpack_assets'
    end
  end

  after 'deploy:updated', 'deploy:compile_webpack_assets'
  after 'deploy:updated', 'deploy:normalize_webpack_assets'
  after 'deploy:reverted', 'deploy:rollback_webpack_assets'

  namespace :webpack do
    task :precompile do
      on release_roles(fetch(:assets_roles)) do
        within release_path do
          with rails_env: fetch(:rails_env), rails_groups: fetch(:rails_assets_groups) do
            execute :rake, "webpack:compile"
          end
        end
      end
    end

    task :backup_manifest do
      on release_roles(fetch(:assets_roles)) do
        within release_path do
          backup_path = release_path.join('webpack_manifest_backup')

          execute :mkdir, '-p', backup_path
          execute :cp,
            detect_manifest_path,
            backup_path
        end
      end
    end

    task :restore_manifest do
      on release_roles(fetch(:assets_roles)) do
        within release_path do
          target = detect_manifest_path
          source = release_path.join('webpack_manifest_backup', File.basename(target))
          if test "[[ -f #{source} && -f #{target} ]]"
            execute :cp, source, target
          else
            msg = 'Rails assets manifest file (or backup file) not found.'
            warn msg
            fail Capistrano::FileNotFound, msg
          end
        end
      end
    end

    def detect_manifest_path
      %w(
        manifest.json
      ).each do |pattern|
        candidate = release_path.join('public', fetch(:webpack_prefix), pattern)
        return capture(:ls, candidate).strip.gsub(/(\r|\n)/,' ') if test(:ls, candidate)
      end
      msg = 'Webpack assets manifest file not found.'
      warn msg
      fail Capistrano::FileNotFound, msg
    end
  end
end

# we can't set linked_dirs in load:defaults,
# as assets_prefix will always have a default value
namespace :deploy do
  task :set_linked_dirs do
    linked_dirs = fetch(:linked_dirs, [])
    unless linked_dirs.include?('public')
      linked_dirs << "public/#{fetch(:webpack_prefix)}"
      set :linked_dirs, linked_dirs.uniq
    end
  end
end

after 'deploy:set_rails_env', 'deploy:set_linked_dirs'

namespace :load do
  task :defaults do
    set :webpack_roles, fetch(:webpack_roles, [:web])
    set :webpack_prefix, fetch(:webpack_prefix, 'webpack')
  end
end
