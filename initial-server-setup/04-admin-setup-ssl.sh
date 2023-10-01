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
# export NEEDRESTART_MODE=a
# export DEBIAN_FRONTEND=noninteractive

# Import environment variables:
# USER
# ADMIN
# Find the absolute path to this script
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ENV_FILE="${THIS_SCRIPT_DIR}/../.env"
# Source .env file only if it exists
test -f "${ENV_FILE}" && source "${ENV_FILE}"

# Assign a default value if it is unset or empty
USER="${USER:-user}"
ADMIN="${ADMIN:-admin}"

# When .env is empty or doesn't exist, then USER
# is set to 'root' when executed from 'root'.
# Thus, we should explicitly set USER to its default
# value of 'user' if its value is 'root'.
if [ "${USER}" == "root" ]; then
    USER="user"
fi

echo "Variables:"
echo "USER: ${USER}"
echo "ADMIN: ${ADMIN}"
echo "----------------------"
echo "Starting the script..."

read -p 'Please enter your domain name (e.g., degenrocket.space): ' SITE_TLD
echo "Domain name: ${SITE_TLD}"

# SSL LetsEncrypt
# https://certbot.eff.org/instructions?ws=nginx&os=snap

# install snapd
# https://snapcraft.io/docs/installing-snapd
apt install snapd
# snap install core
# snap refresh core

# remove apt certbot
apt-get remove certbot -y
snap install --classic certbot

# '-f' option removes the existing destination file if it exists and
# creates the symbolic link regardless, which prevent errors like:
# ln: failed to create symbolic link '/usr/bin/certbot': File exists
ln -sf /snap/bin/certbot /usr/bin/certbot

# certbot --nginx
# certbot --nginx -d yourdomain.com -d www.yourdomain.com
# certbot certonly --noninteractive --agree-tos --cert-name slickstack -d ${SITE_TLD} -d www.${SITE_TLD} -d staging.${SITE_TLD} -d dev.${SITE_TLD} --register-unsafely-without-email --webroot -w /var/www/html/
certbot --noninteractive --agree-tos --nginx --cert-name ${SITE_TLD} -d ${SITE_TLD} -d www.${SITE_TLD} -d staging.${SITE_TLD} --register-unsafely-without-email

# Test auto-renewal
certbot renew --dry-run

# The command to renew certbot is installed in one of the following locations:
# /etc/crontab/
# /etc/cron.*/*
# systemctl list-timers
