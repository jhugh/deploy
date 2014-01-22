#!/bin/bash
#
# # NCI MscWebTech 2013-14
# # Deployment Project
# # Hugh Kelly 13117386 
#
# Script that monitors apache and mysql
# 

source /home/testuser/deploy/func.lib

# ------------------------------------------------------------------
# ------------------------------------------------------------------
# Monitoring Process  <---------------------------------------------
# ------------------------------------------------------------------
# Monitoring ensures that the site is functioning from a HTML, HTTP and other socket 
# layer perspective. It should make sure that 6 key parameters (e.g. memory, I/O etc) 
# are within thresholds. It should report errors. This is kicked off by cron job
# set up by deploy.sh which calls this script. 
#
# Monitoring sub functions:
# - Check mysql port
# - Check http port
# - Check disk space
# - Check memory
# - Check Network availability
# - Check Network utilisation


isApacheRunning
if [ "$?" -eq 1 ]; then
        echo $(date +"%F %T") Apache process is Running
else
        echo $(date +"%F %T") CRITICAL Apache process is not Running
fi

isApacheListening
if [ "$?" -eq 1 ]; then
        echo $(date +"%F %T") Apache is Listening
else
        echo $(date +"%F %T") CRITICAL Apache is not Listening
fi

isApacheRemoteUp
if [ "$?" -eq 1 ]; then
        echo $(date +"%F %T") Remote Apache TCP port is up
else
        echo $(date +"%F %T") CRITICAL Remote Apache TCP port is down
fi

isMysqlRunning
if [ "$?" -eq 1 ]; then
        echo $(date +"%F %T") Mysql process is Running
else
        echo $(date +"%F %T") CRITICAL Mysql process is not Running
fi

isMysqlListening
if [ "$?" -eq 1 ]; then
        echo $(date +"%F %T") Mysql is Listening
else
        echo $(date +"%F %T") CRITICAL Mysql is not Listening
fi

isMysqlRemoteUp
if [ "$?" -eq 1 ]; then
        echo $(date +"%F %T") Remote Mysql TCP port is up
else
        echo $(date +"%F %T") CRITICAL Remote Mysql TCP port is down
fi


getCPU
if [ "$?" -eq 0 ]; then
        echo $(date +"%F %T") CRITICAL Processor usage is above Limits
else
        echo $(date +"%F %T") Processor usage is within normal range
fi
 
freeMEM
if [ "$?" -eq 0 ]; then
        echo $(date +"%F %T") CRITICAL Memory usage is above Limits
else
        echo $(date +"%F %T") Memory usage is within normal range
fi

# - total disk space
TOTALDISKSPACE=`df  /dev/sda1 | sed '1d' | awk '{print $2}' | cut -d'%' -f1`
echo $(date +"%F %T") "Total Disk Space          :" $TOTALDISKSPACE
 
# - available disk space
AVAILABLEDISKSPACE=`df  /dev/sda1 | sed '1d' | awk '{print $4}' | cut -d'%' -f1`
echo $(date +"%F %T") "Available Disk Space      :" $AVAILABLEDISKSPACE

# - percentage used disk space
PERCENTUSEDDISKSPACE=`df -H /dev/sda1 | sed '1d' | awk '{print $5}' | cut -d'%' -f1`
echo $(date +"%F %T") "Used Disk Space           : ${PERCENTUSEDDISKSPACE}%"
 
# - disk capacity threshold
DISKSPACE=`df  /dev/sda1 | sed '1d' | awk '{print $5}' | cut -d'%' -f1`
ALERT=30
if [ ${DISKSPACE} -ge ${ALERT} ]; then
    echo $(date +"%F %T") "WARNING disk ${DISKSPACE}% full"
fi

# - check network 
ping_return=`ping -c1 google.com 2>&1 | grep unknown`
if [ ! "$ping_return" = "" ]; then
       echo $(date +"%F %T") "CRITICAL - Network status : DOWN - attempting to restart !!!"
       service network restart
else
       echo $(date +"%F %T") "Network status            : up"
fi

# - display system status 
rload="$($_CMD uptime |awk -F'average:' '{ print $2}')"
rfreeram="$($_CMD free -mto | grep Mem: | awk '{ print $4 " MB" }')"
rtotalram="$($_CMD free -mto | grep Mem: | awk '{ print $2 " MB" }')"
rusedram="$($_CMD free -mto | grep Mem: | awk '{ print $3 " MB" }')"
 
rhostname="$($_CMD hostname)"
echo $(date +"%F %T") "Current System info:"
echo $(date +"%F %T") "    host       " $rhostname
echo $(date +"%F %T") "    load       " $rload
echo $(date +"%F %T") "    total ram  " $rtotalram
echo $(date +"%F %T") "    free ram   " $rfreeram
echo $(date +"%F %T") "    ram used   " $rusedram
echo $(date +"%F %T") 

