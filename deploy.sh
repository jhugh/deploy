#!/bin/bash
#
# # NCI MscWebTech 2013-14
# # Deployment Project
# # Hugh Kelly 13117386 
#
# Script that sets up cron and kicks off deployment 
#
# Set up logging and monitoring cron job
crontab -r
(crontab -l 2>/dev/null; echo "* * * * * /home/testuser/logmon.sh >> /tmp/logfile.txt") | crontab -
#
# call deployment script 
sudo ./deployment.sh
