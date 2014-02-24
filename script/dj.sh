#!/bin/bash
source /home/railsapps/.profile
cd /home/railsapps/jobsworth/current/script
ruby delayed_job restart production
