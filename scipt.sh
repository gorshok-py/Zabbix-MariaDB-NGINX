#!/bin/bash
	echo 'Выполняется устанновка Nginx + mariadb + Zabbix 5.2 для Ubuntu 18.04 LTS'
	apt update
	apt upgrade
	apt install nginx
	apt install software-properties-common dirmngr apt-transport-https
	apt key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
	apt repository 'deb [arch=amd64,arm64,ppc64el] https://mariadb.mirror.serveriai.lt/repo/10.5/ubuntu bionic main'
	apt update
	apt install mariadb-server
	wget https://repo.zabbix.com/zabbix/5.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.2-1+ubuntu18.04_all.deb
	dpkg -i zabbix-release_5.2-1+ubuntu18.04_all.deb
	apt update
	rm -rf zabbix-release_5.2-1+ubuntu18.04_all.deb
	apt install zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-agent

	echo 'Пакеты установлены.'
	echo '---------------------'
	echo 'Введите пароль root  пользователя MariaDB'
	echo 'При вводе пароль не будет виден!'
	PASSWDDB="$(openssl rand -base64 12)"
	MAINDB=${USER_NAME//[^a-zA-Z0-9]/_}
	mysql -u root -p<<MYSQL_SCRIPT
	create database zabbix character set utf8 collate utf8_bin;
	create user zabbix@localhost identified by '${PASSWDDB}';
	grant all privileges on zabbix.* to zabbix@localhost;
MYSQL_SCRIPT
echo Пользователь и БД zabbix созданы, пароль для бд ''${PASSWDDB}''
sed -i 's/.*# DBPassword=.*/DBPassword='${PASSWDDB}';/'  /etc/zabbix/zabbix_server.conf
ip=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
sed -i 's/.*#        server_name     example.com;.*/'$ip';/'  /etc/zabbix/nginx.conf
sed -i 's/.*#        listen          80;.*/listen 80;/'  /etc/zabbix/nginx.conf

systemctl restart zabbix-server zabbix-agent nginx php7.2-fpm
systemctl enable zabbix-server zabbix-agent nginx php7.2-fpm
echo 'Пакет Zabbix готов к использованию'
