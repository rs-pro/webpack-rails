namespace :deploy do
  task :webpack_set_rails_env do
    set :webpack_rails_env, (fetch(:rails_env) || fetch(:stage))
  end
end

Capistrano::DSL.stages.each do |stage|
  after stage, 'deploy:webpack_set_rails_env'
end
