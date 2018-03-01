set :stages, %w(production staging local candiotto)
set :default_stage, "staging"

require 'capistrano/ext/multistage'

set :application, "jobsworth"
set :repository,  "git@github.com:rafaspinola/jobsworth.git"

set :scm, :git

set :user, "railsapps"
set :use_sudo, false
set :rails_env, "production"

after "deploy:update_code", "deploy:custom_symlinks"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
    run "#{File.join(current_path, 'script/scheduler.rb')} restart"
    run "#{File.join(current_path, 'script/delayed_job')} restart"
  end

  task :custom_symlinks do
    run "rm -rf #{release_path}/config/database.yml"
    run "rm -rf #{release_path}/config/environment.local.rb"
    run "rm -rf #{release_path}/config/application.rb"
    run "ln -s #{shared_path}/database.yml #{release_path}/config/database.yml"
    run "ln -s #{shared_path}/environment.local.rb #{release_path}/config/environment.local.rb"
    run "ln -s #{shared_path}/application.rb #{release_path}/config/application.rb"
  end

  namespace :assets do
    task :precompile, :roles => :web, :except => { :no_release => true } do
      run("rake assets:clean")
      run("rake assets:precompile")
    end
  end  
end