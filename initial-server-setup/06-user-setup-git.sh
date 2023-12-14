#!/bin/bash
# pipefail stops execution if encounters any errors
# set -euo pipefail

# Import environment variables:
# USER
# ADMIN
# APP_NAME
# ALL_APPS_FOLDER
# BACKEND_DIR
# FRONTEND_DIR
# POSTGRES_USER
# POSTGRES_DATABASE
# POSTGRES_PORT
# Find the absolute path to this script
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ENV_FILE="${THIS_SCRIPT_DIR}/../.env"
# Source .env file only if it exists
test -f "${ENV_FILE}" && source "${ENV_FILE}"

# Assign a default value if it is unset or empty
USER="${USER:-user}"
ADMIN="${ADMIN:-admin}"
APP_NAME="${APP_NAME:-degenrocket}"
ALL_APPS_FOLDER="${ALL_APPS_FOLDER:-apps}"
POSTGRES_USER="${POSTGRES_USER:-dbuser}"
POSTGRES_DATABASE="${POSTGRES_DATABASE:-news_database}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

# Temporary set a password to be equal to a database username,
# it should be manually changed after the initial server setup.
# Default password: dbuser
POSTGRES_PASSWORD="${POSTGRES_USER:-dbuser}"

APP_FOLDER="${ALL_APPS_FOLDER}/${APP_NAME}"

# Use environment variables FRONTEND_DIR, BACKEND_DIR
# from .env, otherwise use default ./backend, ./frontend
BACKEND_FOLDER="${BACKEND_DIR:-${APP_FOLDER}/backend}"
FRONTEND_FOLDER="${FRONTEND_DIR:-${APP_FOLDER}/frontend}"

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
echo "APP_NAME: ${APP_NAME}"
echo "ALL_APPS_FOLDER: ${ALL_APPS_FOLDER}"
echo "POSTGRES_USER: ${POSTGRES_USER}"
echo "POSTGRES_DATABASE: ${POSTGRES_DATABASE}"
echo "POSTGRES_PORT: ${POSTGRES_PORT}"
echo "POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}"
echo "APP_FOLDER: ${APP_FOLDER}"
echo "BACKEND_FOLDER: ${BACKEND_FOLDER}"
echo "FRONTEND_FOLDER: ${FRONTEND_FOLDER}"
echo "----------------------"
echo "Starting the script..."

# Create folders for git
bash -c "mkdir -p ${FRONTEND_FOLDER} && mkdir -p ${BACKEND_FOLDER}"

# Download git
bash -c "git clone https://github.com/degenrocket/degenrocket-server.git ${BACKEND_FOLDER}"
bash -c "git clone https://github.com/degenrocket/degenrocket-web.git ${FRONTEND_FOLDER}"

# Install dependencies
bash -c ". ~/.nvm/nvm.sh && cd ${BACKEND_FOLDER} && npm install"
bash -c ". ~/.nvm/nvm.sh && cd ${FRONTEND_FOLDER} && npm install"
# Note: Nuxt package can prompt you to send them anonymous data:
# "Are you interested in participating?
# You can type 'n' and press 'enter' to continue the script.

# Custom components
cp ${FRONTEND_FOLDER}/components/custom/CustomContacts.example.vue ${FRONTEND_FOLDER}/components/custom/CustomContacts.vue
cp ${FRONTEND_FOLDER}/components/custom/CustomIntro.example.vue ${FRONTEND_FOLDER}/components/custom/CustomIntro.vue

# Environment variables
cp ${BACKEND_FOLDER}/.env.example ${BACKEND_FOLDER}/.env
cp ${FRONTEND_FOLDER}/.env.example ${FRONTEND_FOLDER}/.env

ENV_PROMPT_TEXT="
We need to change API_URL in frontend/.env
Please enter your domain name (e.g., degenrocket.space) below.
Do not type 'www' or 'https'.
Alternatively, enter IP address (e.g., 192.168.122.200) if you test in VM.
Note: leave empty (just press enter) if you test locally via localhost.
Your domain name or IP address: "

read -p "${ENV_PROMPT_TEXT}" SITE_TLD
echo "Domain name: \"${SITE_TLD}\""

# Change environment variables API_URL and API_HOST in frontend/.env
# '-n' checks if a variable is not empty
if [ -n "${SITE_TLD}" ]; then
    echo "User provided a domain name ${SITE_TLD}, adjusting frontend/.env"
    # Change the whole line that starts with API_URL or API_HOST
    sed -i "/API_URL=/s/.*/API_URL=http:\/\/${SITE_TLD}/" ${FRONTEND_FOLDER}/.env
    # API_HOST environment variable has been deprecated
    # sed -i "/API_HOST=/s/.*/API_HOST=${SITE_TLD}/" ${FRONTEND_FOLDER}/.env
else
    echo "User didn't provide a domain name, leaving frontend/.env unchanged"
fi

SSL_PROMPT_TEXT="
Did you get an SSL certificate (e.g., via Letsencrypt's certbot)?
Note: choose 'no' if you test locally or in VM via IP address.
yes/no: "

read -p "${SSL_PROMPT_TEXT}" IF_SSL
echo "SSL certificate: \"${IF_SSL}\""

if [[ "${IF_SSL}" =~ ^(yes|y|Yes|YES)$ ]]; then
    echo "User has SSL certificate, changing frontend/.env 'http' to 'https'"
    # Change all occurrences of http to https
    sed -i "s/http/https/g" ${FRONTEND_FOLDER}/.env
else
    echo "No SSL certificate, changing frontend/.env 'https' to 'http'"
    # Change all occurrences of https to http
    sed -i "s/https/http/g" ${FRONTEND_FOLDER}/.env
fi

echo "-----------------"

update_env_var() {
  local var_name="$1"
  local var_value="${!var_name}"
  local env_dir="$2"
  echo "Updating environment variables."
  echo "File: ${env_dir}/.env"
  echo "Variable name: ${var_name}"
  
  if [ -n "${var_value}" ]; then
    echo "Variable value: ${var_value}"
    # Change the whole line that starts with the variable name
    sed -i "/${var_name}=/s/.*/${var_name}=${var_value}/" "${env_dir}/.env"
  else
    echo "Variable ${var_name} is empty"
  fi
}

update_env_var POSTGRES_USER ${BACKEND_FOLDER}
update_env_var POSTGRES_DATABASE ${BACKEND_FOLDER}
update_env_var POSTGRES_PORT ${BACKEND_FOLDER}
update_env_var POSTGRES_PASSWORD ${BACKEND_FOLDER}

echo "Installation is done."
echo "Before building the frontend, adjust customization options in:"
echo "${FRONTEND_FOLDER}/.env"
echo "Also check backend environment variables:"
echo "${BACKEND_FOLDER}/.env"
