server "cfadv.dyndns.org", :app, :web, :db, :primary => true
set :deploy_to, "/home/#{user}/#{application}"
set :port, 6622
set :port_option, " -e 'ssh -p 6622' "