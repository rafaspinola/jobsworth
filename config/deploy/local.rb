server "localhost", :app, :web, :db, :primary => true
set :deploy_to, "/home/#{user}/#{application}-staging"
