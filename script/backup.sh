#/bin/sh
mysqldump jobsworth -u backup | bzip2 > /home/railsapps/backup/backup.sql.bz2
mv /home/railsapps/backup/backup.sql.bz2 /home/railsapps/backup/`date +backup-%Y-%m-%d.sql.bz2`
