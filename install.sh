#!/usr/bin/env bash
echo ""
echo "#########################################################################"
echo ""
echo "Enter the password you want to use for MySQL root: "
read rootpass
echo ""
echo "Enter the password you want to use for Stalker to connect to MySQL: "
read stalkerpass
echo ""
ministra_source=https://raw.githubusercontent.com/edik1963/ministra-ubuntu-24.04/refs/heads/main/ministra-5.6.10.zip;
echo ""
echo "#########################################################################"
echo ""

echo "Setting locales..."
locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

echo "Setting up PHP 7.0 Repository..."

sudo apt-get install -y software-properties-common
add-apt-repository ppa:ondrej/php -y

echo "Running Apt Update & Upgrade..."
apt-get update && apt-get upgrade -y

echo "Installing Initial Packages..."
apt-get install -y dialog net-tools wget git curl \
nano sudo unzip sl lolcat software-properties-common \
aview

echo "Installing Nginx..."
apt-get install nginx nginx-extras -y
/etc/init.d/nginx stop

echo "Installing Apache2..."
apt-get install apache2 -y
/etc/init.d/apache2 stop

echo "Installing Additional Packages..."
apt-get -y install php7.0-dev php7.0-mcrypt php7.0-intl \
php7.0-mbstring php7.0-zip memcached php7.0-memcache \
php7.0 php7.0-xml php7.0-gettext php7.0-soap php7.0-mysql \
php7.0-geoip php-pear nodejs libapache2-mod-php php7.0-curl \
php7.0-imagick php7.0-sqlite3 unzip

echo "Changing PHP Version..."
update-alternatives --set php /usr/bin/php7.0

echo "Installing Phing..."
pear channel-discover pear.phing.info
pear install phing/phing-2.15.0

echo "Installing npm 2.5.11..."
apt-get install npm -y
npm config set strict-ssl false
npm install -g npm@2.15.11
ln -s /usr/bin/nodejs /usr/bin/node

echo "Configuring Timezone..."
sudo ln -fs /usr/share/zoneinfo/America/Los_angeles /etc/localtime
sudo dpkg-reconfigure --frontend noninteractive tzdata

echo "Installing MySQL Server ..."
export DEBIAN_FRONTEND="noninteractive"
echo "mysql-server mysql-server/root_password password $rootpass" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $rootpass" | sudo debconf-set-selections
apt-get install -y mysql-server

echo "Creating MySQL Users..."
mysql -uroot -p$rootpass -e "create database stalker_db;"
mysql -uroot -p$rootpass -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${rootpass}';"
mysql -uroot -p$rootpass -e "CREATE USER 'stalker'@'localhost' IDENTIFIED BY '${stalkerpass}';"
mysql -uroot -p$rootpass -e "GRANT ALL ON stalker_db.* TO 'stalker'@'localhost' WITH GRANT OPTION;"
mysql -uroot -p$rootpass -e "ALTER USER 'stalker'@'localhost' IDENTIFIED WITH mysql_native_password BY '${stalkerpass}';"
mysql -uroot -p$rootpass -e "FLUSH PRIVILEGES;"

echo "Configuring MySQL..."
echo 'sql_mode=""' >> /etc/mysql/mysql.conf.d/mysqld.cnf
echo 'extension=geoip.so' >> /etc/php/7.0/apache2/php.ini
echo 'default_authentication_plugin=mysql_native_password' >> /etc/mysql/mysql.conf.d/mysqld.cnf
service mysql restart

echo "Installing Ministra..."
cd /var/www/html/
wget $ministra_source
unzip ministra-5.6.10.zip
rm -rf *.zip
rm /var/www/html/index*
touch /var/www/html/index.php
echo '<?php' >> /var/www/html/index.php
echo 'header("Location:stalker_portal/c/");' >> /var/www/html/index.php
echo '?>' >> /var/www/html/index.php

echo "Configuring PHP..."
sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php/7.0/apache2/php.ini
ln -s /etc/php/7.0/mods-available/mcrypt.ini /etc/php/8.1/mods-available/
sudo a2dismod mpm_event
sudo a2enmod php7.0
phpenmod mcrypt
a2enmod rewrite
apt-get purge libapache2-mod-php5filter > /dev/null

echo "Setting up Apache2 Config File..."
cd /etc/apache2/sites-enabled/
rm -rf *
wget https://raw.githubusercontent.com/edik1963/ministra-ubuntu-24.04/refs/heads/main/000-default.conf
cd /etc/apache2/
rm -rf ports.conf
wget https://raw.githubusercontent.com/edik1963/ministra-ubuntu-24.04/refs/heads/main/ports.conf

echo "Setting up Nginx Config File..."
cd /etc/nginx/sites-available/
rm -rf default
wget https://raw.githubusercontent.com/edik1963/ministra-ubuntu-24.04/refs/heads/main/default

echo "Restarting Apache2 & Nginx..."
/etc/init.d/apache2 restart
/etc/init.d/nginx restart

echo "Fixing Smart Launcher..."
mkdir /var/www/.npm
chmod 777 /var/www/.npm

echo "Patching Composer..."
cd /var/www/html/stalker_portal/deploy
wget https://raw.githubusercontent.com/edik1963/ministra-ubuntu-24.04/refs/heads/main/composer_version_1.9.1.patch
patch build.xml < composer_version_1.9.1.patch
rm composer_version_1.9.1.patch

echo "Installing custom.ini..."
cd /var/www/html/stalker_portal/server
wget -O custom.ini https://raw.githubusercontent.com/edik1963/ministra-ubuntu-24.04/refs/heads/main/custom.ini

echo "Running Phing..."
sed -i "s/mysql_pass = 1/mysql_pass = $stalkerpass/g" /var/www/html/stalker_portal/server/config.ini
sed -i "s/mysql -u root -p mysql/mysql -u root -p$rootpass mysql/g" /var/www/html/stalker_portal/deploy/build.xml
git config --global http.sslVerify "false"
cd /var/www/html/stalker_portal/deploy
sudo phing
sleep 1
echo -e " \e[32m-------------------------------------------------------------------"
echo ""
echo -e " \e[0mDefault username is: \e[32madmin"
echo -e " \e[0mDefault password is: \e[32m1"
echo ""
echo -e " \e[0mPORTAL WAN : \e[32mhttp://`wget -qO- http://ipecho.net/plain | xargs echo`/stalker_portal"
echo -e " \e[0mPORTAL LAN : \e[32mhttp://`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`/stalker_portal"
echo -e " \e[0mMysql User : \e[32mroot"
echo -e " \e[0mMySQL Pass : \e[32m$rootpass"
echo ""
echo -e " \e[32m--------------------------------------------------------------------\e[0m"