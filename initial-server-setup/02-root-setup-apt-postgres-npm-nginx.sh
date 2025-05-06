#!/bin/bash
# pipefail stops execution if encounters any errors
set -euo pipefail

# Disable Ubuntu 22.04 "Daemon using outdated libraries" prompt
# By setting restart option in /etc/needrestart/needrestart.conf to:
# to 'a' if we want to restart the services automatically
# $nrconf{restart} = 'a';
# to 'l' is we want to simply list the services that need restart.
# $nrconf{restart} = 'l';
# sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
# Another approach to stop prompts (currently disabled): 
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive

# Import environment variables:
# USER_NAME
# ADMIN_NAME
# Find the absolute path to this script
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ENV_FILE="${THIS_SCRIPT_DIR}/../.env"
# Source .env file only if it exists
test -f "${ENV_FILE}" && source "${ENV_FILE}"

# Assign a default value if it is unset or empty
USER="${USER_NAME:-user}"
ADMIN="${ADMIN_NAME:-admin}"

echo "Variables:"
echo "USER: ${USER}"
echo "ADMIN: ${ADMIN}"
echo "----------------------"
echo "Starting the script..."

# Update the system
apt-get -y update && apt-get -y upgrade

################################
# Install postgresql database
# apt-get -y install postgresql-16
echo "Installing postgresql..."
# apt-get -y install postgresql-16

# Source the os-release file
source /etc/os-release
# Print distribution information
echo "Distribution: $NAME"
echo "Version: $VERSION_ID"
echo "Codename: $VERSION_CODENAME"

if [ "$NAME" = "Ubuntu" ] && [ "$VERSION_ID" = "24.04" ]; then
    echo "Installing PostgreSQL 16 on Ubuntu 24.04"
    apt-get update
    apt-get -y install postgresql-16
elif [ "$NAME" = "Debian GNU/Linux" ] && [ "$VERSION_ID" = "12" ]; then
    echo "Installing PostgreSQL 16 on Debian 12"
    apt-get update
    apt-get install -y postgresql-common
    # /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
    # noninteractive allows script execution without user's input
    DEBIAN_FRONTEND=noninteractive /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
    apt-get update
    apt-get -y install postgresql-16
else
    echo "Unsupported distribution: $NAME $VERSION_ID"
    echo "Trying to install PostgreSQL 16..."
    apt-get update
    apt-get -y install postgresql-16
    # exit 1
fi

echo "Configuring postgresql..."
# Change postgresql config otherwise you'll get 'connect econnrefused' error
# Note: adjust the path if your postgresql version is above 16.
# Allow connections from any IP address by changing postgresql.conf:
# "#listen_addresses = 'localhost'" to "listen_addresses = '*'"
sed -i "/#listen_addresses = 'localhost'/s/.*/listen_addresses = '*'/" /etc/postgresql/16/main/postgresql.conf

# Change pg_hba.conf
# host: This indicates the connection type. In this case, it is a TCP/IP
# all: The first all refers to the database(s) this rule applies to. Here, it applies to all databases.
# all: The second all is the user(s) this rule applies to. Here, it applies to all users.
# 0.0.0.0/0 and ::/0: These are the IP address(es) this rule applies to. 0.0.0.0/0 applies to all IPv4 addresses and ::/0 applies to all IPv6 addresses. The /0 is a CIDR notation, which specifies the number of significant bits in the network routing prefix. /0 means that we're not checking any bits of the provided IP address, thus allowing all IP addresses.
# md5: This is the authentication method to use. MD5 password encryption is used here. It means that a client must first supply a valid password for the user name before it can connect to the database.
echo "host    all             all             0.0.0.0/0                       md5" >> /etc/postgresql/16/main/pg_hba.conf
echo "host    all             all             ::/0                            md5" >> /etc/postgresql/16/main/pg_hba.conf

systemctl restart postgresql

# You can test postgresql connection for user 'dbuser' with:
# psql -h localhost -d spasm_database -U dbuser -p 5432

################################
# Download NVM install script
apt-get -y install curl

echo "Installing NVM..."
# su - "${USER}" bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash"
su - "${USER}" bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"

# Install NVM
# 'bash -c' command runs in a non-interactive shell, so it doesn't
# load the environment variables specified in '~/.bashrc' or in
# '~/.bash_profile', where 'nvm' is usually sourced.
# The following command first sources the 'nvm.sh' script to
# set up the 'nvm' command and then executes 'nvm install 18'.
echo "Installing node..."
# su - "${USER}" bash -c ". ~/.nvm/nvm.sh && nvm install 18"
su - "${USER}" bash -c ". ~/.nvm/nvm.sh && nvm install 20"

# Install Node
# su - "${USER}" bash -c ". ~/.nvm/nvm.sh && nvm use 18"
su - "${USER}" bash -c ". ~/.nvm/nvm.sh && nvm use 20"
# su - "${USER}" bash -c ". ~/.nvm/nvm.sh && nvm alias default 18"
su - "${USER}" bash -c ". ~/.nvm/nvm.sh && nvm alias default 20"

# Update npm
su - "${USER}" bash -c ". ~/.nvm/nvm.sh && npm install -g npm@latest"

################################
# Nginx
echo "Installing nginx..."
apt -y install nginx

echo "Configuring nginx..."
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
echo "Success."
