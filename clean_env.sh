#!/bin/bash
#
# # NCI MscWebTech 2013-14
# # Deployment Project
# # Hugh Kelly 13117386 
#
# Script that cleans and prepares env
# 

# ----------------------------------------------------------------
#
# This clean and preparation process will clean up the B/I/T/D server environment.
#

# - Enable sources
apt-get update

# - Stop web and db services
service apache2 stop
service mysql stop

# - Remove apache and install latest version
apt-get -q -y remove apache2
apt-get -q -y install apache2
/usr/sbin/apache2 -v

# - Remove mysql and install latest version
apt-get -q -y remove mysql-server mysql-client
echo mysql-server mysql-server/root_password password password | debconf-set-selections
echo mysql-server mysql-server/root_password_again password password | debconf-set-selections
apt-get -q -y install mysql-server mysql-client
mysql --version

# - Start web and db services
service apache2 start
service mysql start

# - install ruby
sudo apt-get install ruby1.9.1 ruby1.9.1-dev \
  rubygems1.9.1 irb1.9.1 ri1.9.1 rdoc1.9.1 \
  build-essential libopenssl-ruby1.9.1 libssl-dev zlib1g-dev
sudo update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby1.9.1 400 \
         --slave   /usr/share/man/man1/ruby.1.gz ruby.1.gz \
                        /usr/share/man/man1/ruby1.9.1.1.gz \
        --slave   /usr/bin/ri ri /usr/bin/ri1.9.1 \
        --slave   /usr/bin/irb irb /usr/bin/irb1.9.1 \
        --slave   /usr/bin/rdoc rdoc /usr/bin/rdoc1.9.1
ruby --version

# - remove any previous stuff 
cd
rm /tmp/logfile.txt
rm deploy.rep

#
echo ENVIRONMENT CLEANED AND PREPARED
