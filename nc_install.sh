#!/bin/bash
# LAMP Stack + NextCloud install

check_your_privilege () {
    if [[ "$(id -u)" != 0 ]]; then
        echo -e "\e[91mError: This setup script requires root permissions. Please run the script as root.\e[0m" > /dev/stderr
        exit 1
    fi
}
check_your_privilege

clear

echo -e "\e[7mThank you for choosing to install NextCloud. The installation will first Install a LAMP Stack, followed by the installation of NextCloud. \e[0m"

echo
echo

echo -n "Press any key to continue"
read -rsn1

clear

while true; do
    echo -n -e "\e[7mDo you wish to run system updates? [y/n]:\e[0m "
    read yn
    case $yn in
        [yY] | [yY][Ee][Ss] ) echo -ne "\e[36mUpdating System - This may take awhile!\e[0m";  sudo apt-get -y update >/dev/null 2>>lamp.log && sudo apt-get -y upgrade >/dev/null 2>>lamp.log;echo -e "\r\033[K\e[36mUpdating System ----- Complete\e[0m"; break;; #(Run both in one line)
        [nN] | [n|N][O|o] ) echo -e "\e[36mSkipping Updates\e[0m"; break;;  #Boring people don't update
        * ) echo -e "\e[7mPlease answer y or n.\e[0m ";;  #Error handling to get the right answer
    esac
done

echo -ne "\e[36mInstalling Apache2\e[0m"
apt-get install -y apache2 >/dev/null 2>>install.log
echo -e "\r\033[K\e[36mInstalling Apache2 ----- Complete\e[0m"

echo

echo -e "\e[7mWhat is your public IP?\e[0m"
read -p "> " PUBIP

echo

sed -i "222s/.*/ServerName ${PUBIP}/" /etc/apache2/apache2.conf >/dev/null 2>>lamp.log

echo -ne "\e[36mRestarting Apache2\e[0m"
systemctl restart apache2 >/dev/null 2>>lamp.log
echo -e "\r\033[K\e[36mRestarting Apache2 ----- Complete\e[0m"

echo

echo -e "\e[7mWhat is your root Mysql Password??\e[0m"
read -p "> " -s MYSQLPASS

echo
echo

echo -ne "\e[36mInstalling MySQL\e[0m"
debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQLPASS}"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQLPASS}"
apt-get install -y mysql-server >/dev/null 2>>lamp.log
echo -e "\r\033[K\e[36mInstalling MySQL ----- Complete\e[0m"

echo -ne "\e[36mSetting up MySQL\e[0m"
mysql_secure_installation -u root -p"${MYSQLPASS}" << EOF >/dev/null 2>>lamp.log
n
n
y
y
y
y
EOF
echo -e "\r\033[K\e[36mSetting up MySQL ----- Complete\e[0m"

echo -ne "\e[36mInstalling PHP\e[0m"
apt-get install -y php libapache2-mod-php php-mcrypt php-mysql >/dev/null 2>>lamp.log
echo -e "\r\033[K\e[36mInstalling PHP ----- Complete\e[0m"

echo -ne "\e[36mUpdating PHP Config\e[0m"
sed -i "2s/.*/    DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/" /etc/apache2/mods-enabled/dir.conf >/dev/null 2>>lamp.log
echo -e "\r\033[K\e[36mUpdating PHP Config ----- Complete\e[0m"


echo -ne "\e[36mRestarting Apache2\e[0m"
systemctl restart apache2 >/dev/null 2>>lamp.log
echo -e "\r\033[K\e[36mRestarting Apache2 ----- Complete\e[0m"

echo -ne "\e[36mChanging Directory\e[0m"
cd /tmp
echo -e "\r\033[K\e[36mChanging Directory ----- Complete\e[0m"

echo -ne "\e[36mDownloading NextCloud\e[0m"
curl -LO https://download.nextcloud.com/server/releases/latest.tar.bz2 >/dev/null 2>>lamp.log
echo -e "\r\033[K\e[36mDownloading NextCloud ----- Complete\e[0m"

echo -ne "\e[36mExtracting NextCloud\e[0m"
sudo tar -C /var/www -xvjf /tmp/latest.tar.bz2 >/dev/null 2>>lamp.log
echo -e "\r\033[K\e[36mExtracting NextCloud ----- Complete\e[0m"

echo -ne "\e[36mDownloading NextCloud Config Script\e[0m"
wget https://raw.githubusercontent.com/tylerhammer/grafana/development/nextcloud.sh >/dev/null 2>>lamp.log
echo -e "\r\033[K\e[36mDownloading NextCloud Config Script ----- Complete\e[0m"

echo -ne "\e[36mRunning NextCloud Config Script\e[0m"
bash /tmp/nextcloud.sh >/dev/null 2>>lamp.log
echo -e "\r\033[K\e[36mRunning NextCloud Config Script ----- Complete\e[0m"

echo -ne "\e[36mCreating Apache2 Config for NextCloud\e[0m"
cat >/etc/apache2/sites-available/nextcloud.conf<<EOF 2>>lamp.log
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
echo -e "\r\033[K\e[36mCreating Apache2 Config for NextCloud ----- Complete\e[0m"

echo -ne "\e[36mEnabling a2ensite\e[0m"
a2ensite nextcloud >/dev/null 2>>lamp.log
echo -e "\r\033[K\e[36mEnabling a2ensite ----- Complete\e[0m"

echo -ne "\e[36mEnabling a2enmod Rewrite\e[0m"
a2enmod rewrite >/dev/null 2>>lamp.log
echo -e "\r\033[K\e[36mEnabling a2enmod Rewrite ----- Complete\e[0m"

echo -ne "\e[36mUpdating System\e[0m"
apt-get update >/dev/null 2>>lamp.log
echo -e "\r\033[K\e[36mUpdating System ----- Complete\e[0m"

echo -ne "\e[36mInstalling PHP Dependencies for NextCloud\e[0m"
apt-get install -y php-bz2 php-curl php-gd php-imagick php-intl php-mbstring php-xml php-zip >/dev/null 2>>lamp.log
echo -e "\r\033[K\e[36mInstalling PHP Dependencies for NextCloud ----- Complete\e[0m"

echo -ne "\e[36mRestarting Apache2\e[0m"
systemctl restart apache2 >/dev/null 2>>lamp.log
echo -e "\r\033[K\e[36mRestarting Apache2 ----- Complete\e[0m"

mysql -u root -p"${MYSQLPASS}" -e "CREATE DATABASE nextcloud" >/dev/null 2>>lamp.log
mysql -u root -p"${MYSQLPASS}" -e "GRANT ALL ON nextcloud.* to 'nextcloud'@'localhost' IDENTIFIED BY ${MYSQLPASS}" >/dev/null 2>>lamp.log
mysql -u root -p"${MYSQLPASS}" -e "FLUSH PRIVILEGES" >/dev/null 2>>lamp.log
