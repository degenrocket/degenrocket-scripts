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
# USER_NAME
# ADMIN_NAME
# DOMAIN_NAME
# Find the absolute path to this script
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ENV_FILE="${THIS_SCRIPT_DIR}/../.env"
# Source .env file only if it exists
test -f "${ENV_FILE}" && source "${ENV_FILE}"

# Assign a default value if it is unset or empty
USER="${USER_NAME:-user}"
ADMIN="${ADMIN_NAME:-admin}"
DOMAIN_NAME="${DOMAIN_NAME:-}"

echo "Variables:"
echo "USER: ${USER}"
echo "ADMIN: ${ADMIN}"
echo "DOMAIN_NAME: ${DOMAIN_NAME}"
echo "----------------------"
echo "Starting the script..."

####################################
# Check if a domain name has been provided in the .env file.
#
# Option 1. Domain name is provided in the .env file.
# '-n' checks if a variable is not empty
if [ -n "${DOMAIN_NAME}" ]; then
    echo "The domain name is specified in the .env file."
    echo "DOMAIN_NAME: ${DOMAIN_NAME}"

    # Softly prompt a user to confirm the domain name with a timeout,
    # because in the vast majority of cases the domain name specified
    # in the .env file is the intended domain name.
    echo "Do you want to change this domain name? (y/n) "

    # Initialize countdown timer
    COUNTDOWN_ORIGINAL=60
    COUNTDOWN="${COUNTDOWN_ORIGINAL}"

    # Countdown timer
    while [[ $COUNTDOWN -gt 0 ]]; do
      echo -ne "\r$COUNTDOWN seconds remaining"
      # Sleep is disabled, because there is already a 1 sec delay
      # with 'read -t 1' below, which waits for user's input.
      # sleep 1
      ((COUNTDOWN--))

      # Check if user has input any character to stop the countdown.
      # '|| true' is added so the command is not aborted due to 'set -e'.
      read -t 1 -n 1 IF_CHANGE_DOMAIN_ANSWER || true
      if [[ ! -z "${IF_CHANGE_DOMAIN_ANSWER}" ]]; then
        echo -e "\nDetected input: ${IF_CHANGE_DOMAIN_ANSWER}"
        break
      fi
    done

    echo -e "\n"

    # If a user does not respond within a few seconds, set answer to "n"
    if [[ -z "$IF_CHANGE_DOMAIN_ANSWER" ]]; then
      IF_CHANGE_DOMAIN_ANSWER="n"
      echo "A user didn't respond within ${COUNTDOWN_ORIGINAL} seconds."
    fi

    while true; do
      if [[ "${IF_CHANGE_DOMAIN_ANSWER}" =~ ^(yes|y|Yes|YES)$ || \
          "${IF_CHANGE_DOMAIN_ANSWER}" =~ ^(no|n|No|NO)$ ]]; then
        break
      else
        echo "Invalid input '${IF_CHANGE_DOMAIN_ANSWER}'."
        echo "Type 'y' or 'n' and press enter."
        read IF_CHANGE_DOMAIN_ANSWER
      fi
    done

    echo "Answer: ${IF_CHANGE_DOMAIN_ANSWER}"

    if [[ "${IF_CHANGE_DOMAIN_ANSWER}" =~ ^(yes|y|Yes|YES)$ ]]; then
        echo "Changing the domain name..."
        # read -p 'Please enter your domain name (e.g., degenrocket.space): ' DIRTY_SITE_TLD
        echo 'Please enter your domain name (e.g., degenrocket.space): '
        read DIRTY_SITE_TLD
    else
        echo "Continuing with the domain name: ${DOMAIN_NAME}"
        DIRTY_SITE_TLD="${DOMAIN_NAME}"
    fi

# Option 2. Domain name is not provided in the .env file.
else
    echo "The domain name (DOMAIN_NAME) is not specified in the .env file."
    # read -p 'Please enter your domain name (e.g., degenrocket.space): ' DIRTY_SITE_TLD
    echo 'Please enter your domain name (e.g., degenrocket.space): '
    read DIRTY_SITE_TLD
fi

# Loop until a user provides a valid domain name with at least one period
while [[ "${DIRTY_SITE_TLD}" != *.* ]]; do
  echo "ERROR: Not a valid domain name: ${DIRTY_SITE_TLD}"
  # Ask a user to input a domain name again
  # read -p 'Please enter your domain name (e.g., degenrocket.space): ' DIRTY_SITE_TLD
  echo 'Please enter your domain name (e.g., degenrocket.space): '
  read DIRTY_SITE_TLD
done

# Remove 'http://'
DIRTY_SITE_TLD="${DIRTY_SITE_TLD#http://}"

# Remove 'https://'
DIRTY_SITE_TLD="${DIRTY_SITE_TLD#https://}"

# Remove 'www.'
DIRTY_SITE_TLD="${DIRTY_SITE_TLD#www.}"

# Remove 'staging.' from 'staging.example.com', but not from 'staging.com'.
# Check if the string contains more than one period
if [[ "$DIRTY_SITE_TLD" =~ .*\..*\..* ]]; then
  # Remove 'staging.' only if the string starts with it
  if [[ "$DIRTY_SITE_TLD" == staging.* ]]; then
    DIRTY_SITE_TLD="${DIRTY_SITE_TLD#staging.}"
  fi
fi

# Cleaning is done
CLEAN_SITE_TLD="${DIRTY_SITE_TLD}"

SITE_TLD="${CLEAN_SITE_TLD}"

echo "Final domain name: ${SITE_TLD}"

# Check if the domain name can be resolved
echo "Trying to resolve the domain name..."

# Sleep is added for UX so a user can terminate the command
# if a wrong domain name has been specified before pinging it
# due privacy reasons.
sleep 5

# Temporary disable exitting on error to check the domain name.
set +e

# Ping the domain
host "${SITE_TLD}"

# The $? variable contains the exit status of the last command
# If the host command is successful, its exit status is 0,
# otherwise it's non-zero
if [ $? -eq 0 ]; then
  echo "The domain ${SITE_TLD} can be resolved."
  echo "Proceeding..."
else
  echo "ERROR: The domain ${SITE_TLD} cannot be resolved."
  echo "Make sure that you've configured DNS records,"
  echo "and that you have a stable internet connection."
  echo "Please refer to the README.md file for the instruction."
  echo "It's suggested to:"
  echo "- Exit this script."
  echo "- Investigate and fix the issue."
  echo "- Run this script again."
  echo "You can try to ping your website from another terminal:"
  echo "host '${SITE_TLD}'"
  echo "If the command above returns a valid IP address,"
  echo "then you can continue this script."

  CANNOT_RESOLVE_PROMPT_TEXT="
Proceed further even though the domain name cannot be resolved?
yes/no: "

  read -p "${CANNOT_RESOLVE_PROMPT_TEXT}" IF_PROCEED_ERROR
  # echo "Proceed: \"${IF_PROCEED_ERROR}\""

  if [[ "${IF_PROCEED_ERROR}" =~ ^(yes|y|Yes|YES)$ ]]; then
      echo "Continuing the script..."
  else
      echo "Exitting the script."
      exit 0
  fi
fi

# Re-enable the -e option to exit the script on any error
set -e

# SSL LetsEncrypt
# https://certbot.eff.org/instructions?ws=nginx&os=snap

# install snapd
# https://snapcraft.io/docs/installing-snapd
apt-get -y install snapd
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
