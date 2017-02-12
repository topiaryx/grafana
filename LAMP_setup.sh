#!/bin/bash

apt-get -y update

apt-get install -y apache2

echo -e "\e[7mWhat is your public IP?\e[0m"
read -p "> " PUBIP

sed -i "222s/.*/ServerName ${PUBIP}/" /etc/apache2/apache2.conf >/dev/null 2>>lamp.log

systemctl restart apache2

apt-get install -y mysql-server

mysql_secure_installation << EOF
n
n
y
y
y
y
EOF

apt-get install -y php libapache2-mod-php php-mcrypt php-mysql

sed -i "2s/.*/    DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/" /etc/apache2/mods-enabled/dir.conf >/dev/null 2>>lamp.log

sudo systemctl restart apache2

cd /tmp

curl -LO https://download.nextcloud.com/server/releases/latest.tar.bz2

sudo tar -C /var/www -xvjf /tmp/latest.tar.bz2

wget

bash /tmp/nextcloud.sh

cat >/etc/apache2/sites-available/nextcloud.conf<<EOF
Alias /nextcloud "/var/www/nextcloud/"

<Directory /var/www/nextcloud/>
    Options +FollowSymlinks
    AllowOverride All

    <IfModule mod_dav.c>
        Dav off
    </IfModule>

    SetEnv HOME /var/www/nextcloud
    SetEnv HTTP_HOME /var/www/nextcloud

</Directory>
EOF

a2ensite nextcloud

a2enmod rewrite

apt-get update

apt-get install -y php-bz2 php-curl php-gd php-imagick php-intl php-mbstring php-xml php-zip

systemctl reload apache2

echo -e "\e[7mWhat is your root Mysql Password??\e[0m"
read -p "> " -s MYSQLPASS

mysql -u root -p'${MYSQLPASS}' -e "CREATE DATABASE nextcloud"
mysql -u root -p'${MYSQLPASS}' -e "GRANT ALL ON nextcloud.* to 'nextcloud'@'localhost' IDENTIFIED BY '${MYSQLPASS}'"
mysql -u root -p'${MYSQLPASS}' -e "FLUSH PRIVILEGES"
