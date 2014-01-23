#!/bin/bash
#
# # NCI MscWebTech 2013-14
# # Deployment Project
# # Hugh Kelly 13117386 
#
# Script that deploys a website from github
# 
#    1  Build Process
#    2  Integration Process
#    3  Test Process
#    4  Deployment Process
#

ADMINISTRATOR="mscwebtech.kelly@gmail.com"
PASSWORD="Y0urPetsName"
DEBUG=false

# FUNCTION LIBRARY
source /home/testuser/deploy/func.lib


# ------------------------------------------------------------------
# ------------------------------------------------------------------
# 1 BUILD process  <------------------------------------------------
# ------------------------------------------------------------------
#
# The build process will download content from a repository (e.g. github). It 
# checks that all components and resources are in place for testing. The build 
# process makes sure that the environment is clean and revisions of necessary 
# components are at the right level.
# 

# - Set up sandbox 
cd /tmp
SANDBOX=sandbox_$RANDOM
mkdir $SANDBOX
cd    $SANDBOX/
ERRORCHECK=0

# - Download from Github
if [[ "DEBUG" == "true" ]]
then
  mkdir webpackage               # make simple static web site
  touch webpackage/index.htm
  touch webpackage/form.htm
  touch webpackage/script1.plx
  touch webpackage/script2.plx
else
  git clone https://github.com/jhugh/NCIRL.git
  mv NCIRL webpackage
fi

# - Create Stage Directories in sandbox
mkdir build
mkdir integrate
mkdir test
mkdir deploy

# - Make webpackage and move webpackage to 'build'
tar -zcvf webpackage_preBuild.tgz webpackage
if [ "$?" -ne "0" ]; then
  ERRORCHECK+=1
fi

# - Get md5sum to check if webpackage has changed since last deploy
MD5SUM=$(md5sum webpackage_preBuild.tgz | cut -f 1 -d' ')
PREVMD5SUM=$(cat /tmp/md5sum)
FILECHANGE=0
if [[ "$MD5SUM" != "$PREVMD5SUM" ]]
then
        FILECHANGE=1
        echo $MD5SUM not equal to $PREVMD5SUM
else
        FILECHANGE=0
        echo $MD5SUM equal to $PREVMD5SUM
fi
echo $MD5SUM > /tmp/md5sum
if [ $FILECHANGE -eq 0 ]
then
        echo no change in files, doing nothing and exiting
        cd
        exit
fi

# - Move webpackage to 'build'
mv webpackage_preBuild.tgz build    
rm -rf webpackage
cd build
tar -zxf webpackage_preBuild.tgz
if [ "$?" -ne "0" ]; then
  ERRORCHECK+=2
fi

# - Check build
INDEX_EXIST=$(ls webpackage/Apache/www | grep 'index.html')
if [[ "$INDEX_EXIST" != "index.html" ]]
then
  ERRORCHECK+=4
fi
tar -zcf webpackage_preIntegrate.tgz webpackage
if [ "$?" -ne "0" ]; then
  ERRORCHECK+=8
fi

# - If errors send email to admin
if [ $ERRORCHECK -ne 0 ]
then
        echo $ERRORCHECK build errors, exiting
        /home/testuser/deploy/sendmail.rb $ADMINISTRATOR $PASSWORD "CRITICAL Deploy Error: $ERRORCHECK" "There is a problem with Build."
        cd
        exit
else
        echo $ERRORCHECK build errors
fi
B_ERRORS=$ERRORCHECK


# ------------------------------------------------------------------
# ------------------------------------------------------------------
# 2 INTEGRATION process <-------------------------------------------
# ------------------------------------------------------------------
#
# Integration integrates the static content with the components that provide the
# dynamic content, so as to create the overall content.
#
ERRORCHECK=0

# - Put webpackage in integrate area
mv webpackage_preIntegrate.tgz ../integrate
rm -rf webpackage
cd ../integrate

# - Extract webpackage
tar -zxf webpackage_preIntegrate.tgz
if [ "$?" -ne "0" ]; then
  ERRORCHECK+=1
fi

# - Modify static html
#DATESTAMP=$(date +"%D")
TIMESTAMP=$(date +"%m-%d-%Y %T")
#TIMEDATE="$DATESTAMP $TIMESTAMP"
echo $TIMESTAMP 
sed -i s/"It works"/"MScWebTech Deployment project $TIMESTAMP"/ webpackage/Apache/www/index.html
if [ "$?" -ne "0" ]; then
  ERRORCHECK+=2
fi

# - Tar up for Test phase
tar -zcf webpackage_preTest.tgz webpackage
if [ "$?" -ne "0" ]; then
  ERRORCHECK+=4
fi

# - If errors send email to admin 
if [ $ERRORCHECK -ne 0 ]
then
        echo $ERRORCHECK integration errors, exiting
        /home/testuser/deploy/sendmail.rb $ADMINISTRATOR $PASSWORD "CRITICAL Deploy Error: $ERRORCHECK" "There is a problem with Integration."
        cd
        exit
else
        echo $ERRORCHECK integration errors
fi
I_ERRORS=$ERRORCHECK



# ------------------------------------------------------------------
# ------------------------------------------------------------------
# 3 TEST process  <-------------------------------------------------
# ------------------------------------------------------------------
#
# The test process makes sure that the static content is properly constructed 
# (HTML tags etc.), and that the dynamic content functions as required. 
#
ERRORCHECK=0

# - Move webpackage to test area
mv webpackage_preTest.tgz ../test
rm -rf webpackage
cd ../test

# - Extract webpackage to test are
tar -zxf webpackage_preTest.tgz
if [ "$?" -ne "0" ]; then
  ERRORCHECK+=1
fi

# - Html checks
HTMLTAG=$(cat webpackage/Apache/www/index.html | grep '<html>' | cut -d '>' -f 1)
if [[ "$HTMLTAG" != "<html" ]]
then
  ERRORCHECK+=2
fi
HTMLTAG=$(cat webpackage/Apache/www/index.html | grep 'MScWebTech' | cut -d '>' -f 1)
if [[ "$HTMLTAG" != "<html" ]]
then
  ERRORCHECK+=4
fi

# - Tar webpackage for deploy
tar -zcf webpackage_preDeploy.tgz webpackage
if [ "$?" -ne "0" ]; then
  ERRORCHECK+=8
fi

# - If errors send email to admin
if [ $ERRORCHECK -ne 0 ]
then
        echo $ERRORCHECK test errors, exiting
        /home/testuser/deploy/sendmail.rb $ADMINISTRATOR $PASSWORD "CRITICAL Deploy Error: $ERRORCHECK" "There is a problem with Test."
        cd
        exit
else
        echo $ERRORCHECK test errors
fi
T_ERRORS=$ERRORCHECK



# ------------------------------------------------------------------
# ------------------------------------------------------------------
# 4 DEPLOYMENT process  <-------------------------------------------
# ------------------------------------------------------------------
#
# Deployment ensures that all components (content, packages etc) and resources 
# (memory, disk, I/O etc) are in place for production. It unpacks the content 
# and moves it to its proper location on the production server. It backs up the 
# content prior to deployment of new content. If the deployment fails, the old 
# site is kept in place.  
#

# - If no errors move webpackage to deploy area and extract
if [ $ERRORCHECK -eq 0 ]
then
        mv webpackage_preDeploy.tgz ../deploy
        rm -rf webpackage
        cd ../deploy
        tar -zxf webpackage_preDeploy.tgz  
fi

# - Stop services
service apache2 stop
service mysql stop

# - Remove and re-install apache
apt-get -q -y remove apache2
apt-get -q -y install apache2

# - Remove and re-install mysql
apt-get -q -y remove mysql-server mysql-client
echo mysql-server mysql-server/root_password password password | debconf-set-selections
echo mysql-server mysql-server/root_password_again password password | debconf-set-selections
apt-get -q -y install mysql-server mysql-client

# - Backup up existing website
mkdir backup
mkdir backup/www
cp /var/www/* backup/www
mkdir backup/cgi-bin
cp /usr/lib/cgi-bin/* backup/cgi-bin

# - Copy website
cp webpackage/Apache/www/* /var/www/
if [ "$?" -ne "0" ]; then
  ERRORCHECK+=1
fi
cp webpackage/Apache/cgi-bin/* /usr/lib/cgi-bin/
if [ "$?" -ne "0" ]; then
  ERRORCHECK+=2
fi
chmod a+x /usr/lib/cgi-bin/*
if [ "$?" -ne "0" ]; then
  ERRORCHECK+=4
fi

# - Start db service
service mysql start

# - Backup Existing database
mysqldump -uroot -ppassword --databases dbtest > backup.sql
if [ "$?" -ne "0" ]; then
  ERRORCHECK+=8
fi

# - Check mysql database
cat <<FINISH | mysql -uroot -ppassword
drop database if exists dbtest;
CREATE DATABASE dbtest;
GRANT ALL PRIVILEGES ON dbtest.* TO dbtestuser@localhost IDENTIFIED BY 'dbpassword';
use dbtest;
drop table if exists custdetails;
create table if not exists custdetails (
name         VARCHAR(30)   NOT NULL DEFAULT '',
address         VARCHAR(30)   NOT NULL DEFAULT ''
);
insert into custdetails (name,address) values ('John Smith','Street Address'); 
select * from custdetails into outfile 'db_check.txt';
FINISH
DBCHECK=$(cat /var/lib/mysql/dbtest/db_check.txt | grep 'John Smith' | cut -d ' ' -f 1)
if [[ "$DBCHECK" != "John" ]] 
then
  ERRORCHECK+=16
fi
rm /var/lib/mysql/dbtest/db_check.txt

# - Restore original dbtest database
mysql -uroot -ppassword < backup.sql
if [ "$?" -ne "0" ]; then
  ERRORCHECK+=32
fi

# - Start web service
service apache2 start

# - Check deployed web page
wget -O received_page.txt "http://localhost/index.html"
if [ "$?" -ne "0" ]; then
  ERRORCHECK+=64
fi
HTMLTAG=$(cat received_page.txt | grep 'MScWebTech' | cut -d '>' -f 1)
if [[ "$HTMLTAG" != "<html" ]] 
then
  ERRORCHECK+=128
fi

# - Errorcheck, rollback and send email if issues
if [ $ERRORCHECK -ne 0 ]
then
        echo $ERRORCHECK deploy errors, rolling back and exiting
        echo Rolling Back Website
        service apache2 stop
        cp backup/www/* /var/www/
        cp backup/cgi-bin/* /usr/lib/cgi-bin/
        chmod a+x /usr/lib/cgi-bin/*
        service apache2 start
        /home/testuser/deploy/sendmail.rb $ADMINISTRATOR $PASSWORD "CRITICAL Deploy Error: $ERRORCHECK" "There is a problem with Deploy."
        cd
        exit
else
        echo $ERRORCHECK deploy errors
fi
D_ERRORS=$ERRORCHECK

# - Tidy up
cd /tmp
rm -rf $SANDBOX
cd

# - report all errors
echo
echo Error Summary
echo Build errors: $B_ERRORS
echo Intgration errors: $I_ERRORS
echo Test errors: $T_ERRORS
echo Deploy errors: $D_ERRORS
echo


# - check all is running ok
ERRORCOUNT=0
# - CHECK MYSQL
isMysqlRunning
if [ "$?" -eq 1 ]; then
        echo Mysql process is Running
else
        echo Mysql process is not Running
        ERRORCOUNT=$((ERRORCOUNT+1))
fi

isMysqlListening
if [ "$?" -eq 1 ]; then
        echo Mysql is Listening
else
        echo Mysql is not Listening
        ERRORCOUNT=$((ERRORCOUNT+1))
fi

isMysqlRemoteUp
if [ "$?" -eq 1 ]; then
        echo Remote Mysql TCP port is up
else
        echo Remote Mysql TCP port is down
        ERRORCOUNT=$((ERRORCOUNT+1))
fi

# - CHECK HTTP
isApacheRunning
if [ "$?" -eq 1 ]; then
        echo Apache process is Running
else
        echo Apache process is not Running
        ERRORCOUNT=$((ERRORCOUNT+1))
fi

isApacheListening
if [ "$?" -eq 1 ]; then
        echo Apache is Listening
else
        echo Apache is not Listening
        ERRORCOUNT=$((ERRORCOUNT+1))
fi

isApacheRemoteUp
if [ "$?" -eq 1 ]; then
        echo Remote Apache TCP port is up
else
        echo Remote Apache TCP port is down
        ERRORCOUNT=$((ERRORCOUNT+1))
fi


# - SEND EMAIL WHEN DEPLOYMENT IS COMPLETE
if  [ $ERRORCOUNT -gt 0 ]
then
        ./deploy/sendmail.rb $ADMINISTRATOR $PASSWORD "CRITICAL Deploy Issue" "There are $ERRORCOUNT errors with Apache or Mysql"
else
        ./deploy/sendmail.rb $ADMINISTRATOR $PASSWORD "No Deploy Issue" "Deployment completed successfully"
fi
