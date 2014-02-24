server "54.207.45.173", :app, :web, :db, :primary => true
set :deploy_to, "/home/#{user}/#{application}"
set :port_option, ""