#!/bin/bash

# Definition of variables
DBNAME=wordpress
DBUSER=wordpress_user
DBPASSWORD=pa55wordwordpre55

# Update and Upgrade
sudo apt update -y && sudo apt upgrade -y

# Install Nginx WebServer
sudo apt install nginx -y

# Install MariaDb
sudo apt install mariadb-server -y

# Install PHP
sudo apt install php-mysql php-fpm -y

# Download latest Version of Wordpress
sudo wget -O - https://wordpress.org/latest.tar.gz | sudo tar -xzvf - -C /var/www/
sudo chown -R www-data:www-data /var/www/wordpress

# Configure Nginx for Wordpress
echo 'upstream wp-php-handler {
    server unix:/var/run/php/php8.2-fpm.sock;
}
server {
    listen 80;
    server_name wordpress.paulajuliabalza.online;
    root /var/www/wordpress/;
    index index.php;
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass wp-php-handler;
    }
}' | sudo tee /etc/nginx/sites-available/wordpress.conf > /dev/null

#Remove nginx default file
sudo rm /etc/nginx/sites-available/default
sudo rm /etc/nginx/sites-enabled/default

#Create symbolic link
sudo ln -s /etc/nginx/sites-available/wordpress.conf /etc/nginx/sites-enabled/

# Reload Configuration
sudo systemctl reload nginx.service

# Configuration Mariadb
sudo mariadb << EOF
CREATE DATABASE $DBNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
GRANT ALL ON wordpress.* TO '$DBUSER'@'localhost' IDENTIFIED BY '$DBPASSWORD';
FLUSH PRIVILEGES;
EOF

# Configure Wordpress user and DB
sudo cp /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php
sudo sed -i "s/database_name_here/$DBNAME/g" /var/www/wordpress/wp-config.php
sudo sed -i "s/username_here/$DBUSER/g" /var/www/wordpress/wp-config.php
sudo sed -i "s/password_here/$DBPASSWORD/g" /var/www/wordpress/wp-config.php

# Reload Configuration
sudo systemctl reload nginx.service


