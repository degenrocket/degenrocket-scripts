#!/bin/bash
# pipefail stops execution if encounters any errors
# set -euo pipefail

USER="user"
ADMIN="admin"
APP_NAME="degenrocket"

ALL_APPS_FOLDER="apps"
# APP_FOLDER="${ALL_APPS_FOLDER}/$(date +%Y%m%d)"
APP_FOLDER="${ALL_APPS_FOLDER}/${APP_NAME}"
FRONTEND_FOLDER="${APP_FOLDER}/frontend"
BACKEND_FOLDER="${APP_FOLDER}/backend"

echo "${APP_FOLDER}"
echo "${FRONTEND_FOLDER}"
echo "${BACKEND_FOLDER}"

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
We need to change API_HOST and API_URL in frontend/.env
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
    sed -i "/API_HOST=/s/.*/API_HOST=${SITE_TLD}/" ${FRONTEND_FOLDER}/.env
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

echo "Installation is done."
echo "Before building the app, adjust customization options in"
echo "${FRONTEND_FOLDER}/.env"
