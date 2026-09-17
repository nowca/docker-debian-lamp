# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv

ARG OS_NAME=debian
ARG OS_VERSION=bookworm
ARG MYSQL_PACKAGE=mysql-8.4-lts
ARG MYSQL_ROOT_PASSWORD=rootROOT123!
ARG CREATE_PHPINFO_FILE=true
ARG PHPMYADMIN_WEB_FOLDERNAME=phpmyadmin

### stage: linux
FROM debian:$DEBIAN_VERSION AS lamp-linux

# update system
RUN apt-get update && apt-get upgrade -y

# install linux-tools
RUN apt-get install -y sudo vim net-tools htop wget curl gnupg lsb-release


### stage: apache
FROM lamp-linux AS lamp-apache

## install apache-webserver
RUN apt-get install -y apache2


### stage: mysql
FROM lamp-apache AS lamp-mysql
ARG DEBIAN_VERSION
ARG MYSQL_PACKAGE

## install mysql-database-server

# add mysql repo to sources
RUN echo "deb http://repo.mysql.com/apt/${OS_NAME}/ ${OS_VERSION} ${MYSQL_PACKAGE}" > /etc/apt/sources.list.d/mysql.list

# get public key
RUN PUBKEY=$(apt-get update 2>&1 | sed -En 's/.*(NO_PUBKEY|Missing key) ([[:xdigit:]]+).*/\2/p' | head -1) \
&& gpg --keyserver keyserver.ubuntu.com --recv-keys ${PUBKEY} \
&& gpg --armor --export ${PUBKEY} | gpg --dearmor -o /etc/apt/keyrings/mysql.gpg 

# set signing key path
RUN echo "deb [signed-by=/etc/apt/keyrings/mysql.gpg] http://repo.mysql.com/apt/${OS_NAME}/ ${OS_VERSION} ${MYSQL_PACKAGE}" > /etc/apt/sources.list.d/mysql.list

RUN apt-get update
RUN apt-get upgrade

# configure default configuration

ARG MYSQL_ROOT_PASSWORD

RUN echo "mysql-community-server mysql-community-server/root-pass password ${MYSQL_ROOT_PASSWORD}" | debconf-set-selections
RUN echo "myql-community-server mysql-community-server/re-root-pass password ${MYSQL_ROOT_PASSWORD}" | debconf-set-selections
RUN echo "mysql-community-server mysql-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)" | debconf-set-selections

# get my sql
RUN DEBIAN_FRONTEND=noninteractive apt install -y mysql-server

# secure installation
RUN ( /usr/bin/mysqld_safe > /dev/null 2>&1 & ) \
&& ( while [ ! -S "/var/run/mysqld/mysqld.sock" ]; do sleep 1; done ) \
&& mysql_secure_installation -D --password=${MYSQL_ROOT_PASSWORD}


### stage: php
FROM lamp-mysql AS lamp-php

ARG CREATE_PHPINFO_FILE
ARG PHPMYADMIN_WEB_FOLDERNAME

## install php-modules
RUN apt-get install -y php libapache2-mod-php php-cli php-mysql

# create phpinfo-file
RUN if [ "$CREATE_PHPINFO_FILE" = "true" ]; then echo "<?php echo phpinfo(); ?>" > /var/www/html/phpinfo.php; fi

## install phpmyadmin
RUN ( /usr/bin/mysqld_safe > /dev/null 2>&1 & )

RUN echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections
RUN echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections

RUN apt-get install -y phpmyadmin

# set web-server-url
RUN ln -s /usr/share/phpmyadmin/ /var/www/html/${PHPMYADMIN_WEB_FOLDERNAME}


### run server
EXPOSE 80 3306

RUN ( printf '#!'"/bin/sh\n\nservice apache2 start\n/usr/bin/mysqld_safe > /dev/null 2>&1 &\n/bin/bash\n" > /run/init.sh )
RUN chmod +x /run/init.sh
CMD ["/run/init.sh"]