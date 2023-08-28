#!/bin/bash
# pipefail stops execution if encounters any errors
set -euo pipefail

# Disable Ubuntu 22.04 "Daemon using outdated libraries" prompt
# By setting restart option in /etc/needrestart/needrestart.conf to:
# to 'a' if we want to restart the services automatically
# $nrconf{restart} = 'a';
# to 'l' is we want to simply list the services that need restart.
# $nrconf{restart} = 'l';
sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf

USER="user"
ADMIN="admin"

# Update the system
apt-get -y update && apt-get -y upgrade

################################
# Install postgresql database
apt-get -y install postgresql-14

# Change postgresql config otherwise you'll get 'connect econnrefused' error
# Note: adjust the path if your postgresql version is above 14.
# Allow connections from any IP address by changing postgresql.conf:
# "#listen_addresses = 'localhost'" to "listen_addresses = '*'"
sed -i "/#listen_addresses = 'localhost'/s/.*/listen_addresses = '*'/" /etc/postgresql/14/main/postgresql.conf

# Change pg_hba.conf
# host: This indicates the connection type. In this case, it is a TCP/IP
# all: The first all refers to the database(s) this rule applies to. Here, it applies to all databases.
# all: The second all is the user(s) this rule applies to. Here, it applies to all users.
# 0.0.0.0/0 and ::/0: These are the IP address(es) this rule applies to. 0.0.0.0/0 applies to all IPv4 addresses and ::/0 applies to all IPv6 addresses. The /0 is a CIDR notation, which specifies the number of significant bits in the network routing prefix. /0 means that we're not checking any bits of the provided IP address, thus allowing all IP addresses.
# md5: This is the authentication method to use. MD5 password encryption is used here. It means that a client must first supply a valid password for the user name before it can connect to the database.
echo "host    all             all             0.0.0.0/0                       md5" >> /etc/postgresql/14/main/pg_hba.conf
echo "host    all             all             ::/0                            md5" >> /etc/postgresql/14/main/pg_hba.conf

systemctl restart postgresql

# You can test postgresql connection for user 'dbuser' with:
# psql -h localhost -d news_database -U dbuser -p 5432

################################
# Download NVM install script
su - "${USER}" bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash"

# Install NVM
# 'bash -c' command runs in a non-interactive shell, so it doesn't
# load the environment variables specified in '~/.bashrc' or in
# '~/.bash_profile', where 'nvm' is usually sourced.
# The following command first sources the 'nvm.sh' script to
# set up the 'nvm' command and then executes 'nvm install 18'.
su - "${USER}" bash -c ". ~/.nvm/nvm.sh && nvm install 18"

# Install Node
su - "${USER}" bash -c ". ~/.nvm/nvm.sh && nvm use 18"
su - "${USER}" bash -c ". ~/.nvm/nvm.sh && nvm alias default 18"

# Update npm
su - "${USER}" bash -c ". ~/.nvm/nvm.sh && npm install -g npm@latest"

################################
# Nginx
apt -y install nginx

NGINX_CONFIG="
server {
	listen 80 default_server;
	listen [::]:80 default_server;

	root /var/www/html;

	index index.html index.htm index.nginx-debian.html;

	server_name _;

	location / {
	  proxy_pass http://localhost:3000; #whatever port app runs on
	  proxy_http_version 1.1;
	  proxy_set_header Upgrade \$http_upgrade;
	  proxy_set_header Connection 'upgrade';
	  proxy_set_header Host \$host;
	  proxy_cache_bypass \$http_upgrade;
	  #  proxy_set_header X-Real-IP \$remote_addr;
	  #  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
	  #  proxy_set_header X-NginX-Proxy true;
	  #  proxy_redirect http://localhost:3000/ https://\$server_name;
	}

	location /api {
		proxy_pass http://api-server/api; #whatever port app runs on
		proxy_http_version 1.1;
		proxy_set_header Upgrade \$http_upgrade;
		proxy_set_header Connection 'upgrade';
		proxy_set_header Host \$host;
		proxy_cache_bypass \$http_upgrade;
	}
}

upstream api-server {
    server localhost:5000;
}
"

echo "${NGINX_CONFIG}" > /etc/nginx/sites-available/default
echo "Nginx config has been changed at: /etc/nginx/sites-available/default"

# Test nginx config
nginx -t

service nginx restart

