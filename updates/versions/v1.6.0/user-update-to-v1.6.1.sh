#!/bin/bash
# pipefail stops execution if encounters any errors
set -euo pipefail

# Disable Ubuntu 22.04 "Daemon using outdated libraries" prompt
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive

BACKEND_DIR="${HOME}/apps/degenrocket/backend"
FRONTEND_DIR="${HOME}/apps/degenrocket/frontend"

# Delete any local git changes and download a new version
cd "${BACKEND_DIR}" && git reset --hard HEAD && git pull
cd "${FRONTEND_DIR}" && git reset --hard HEAD && git pull

# If new environment variables have been added to .env.example,
# the we should copy missing lines from .env.example to .env
copy_env() {
  local ENV_DIR="$1"

  # Read each line from the .env.example file
  while IFS= read -r line; do
    # Extract the portion of the line before '='
    key=$(echo "$line" | cut -d '=' -f 1)

    # Check if the key exists in .env
    grep -q "^$key=" "$ENV_DIR/.env" || echo "$line" >> "$ENV_DIR/.env"
  done < "$ENV_DIR/.env.example"
}

# Copy missing .env lines for backend and frontend
echo "Adding missing lines to ${BACKEND_DIR}/.env"
copy_env "${BACKEND_DIR}"
echo "Adding missing lines to ${FRONTEND_DIR}/.env"
copy_env "${FRONTEND_DIR}"

# Install npm packages if new packages have been added
cd "${BACKEND_DIR}" && npm install
cd "${FRONTEND_DIR}" && npm install && npm run build

# Normally, 'pm2 restart all' is enough, but with this update
# we added new custom ports for dev, staging, production for
# both frontend and backend using pm2 ecosystem config files,
# so in this case we need to delete previous app instances
# and then start new ones.
pm2 delete all

cd "${BACKEND_DIR}" && npm run prod
cd "${FRONTEND_DIR}" && npm run prod

pm2 save

echo "Done"

# Congrats, the update is done.

# If you will change environment variables, then
# don't forget to run npm build after that, e.g.:
# $ cd ~/apps/degenrocket/frontend && npm run build
# and also restart all pm2 app instances, e.g.:
# $ pm2 restart all
