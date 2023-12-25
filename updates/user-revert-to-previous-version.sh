#!/bin/bash
# pipefail stops execution if encounters any errors
set -euo pipefail

# Disable Ubuntu 22.04 "Daemon using outdated libraries" prompt
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive

# Import environment variables:
# BACKEND_DIR
# FRONTEND_DIR
# BACKEND_PM2_INSTANCE_NAME
# FRONTEND_PM2_INSTANCE_NAME
# Find the absolute path to this script
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ENV_FILE="${THIS_SCRIPT_DIR}/../.env"
# Source .env file only if it exists
test -f "${ENV_FILE}" && source "${ENV_FILE}"

# Assign a default value if it is unset or empty
BACKEND_DIR="${BACKEND_DIR:-$HOME/apps/degenrocket/backend}"
FRONTEND_DIR="${FRONTEND_DIR:-$HOME/apps/degenrocket/frontend}"
BACKEND_PM2_INSTANCE_NAME="${BACKEND_PM2_INSTANCE_NAME:-dr-prod-back}"
FRONTEND_PM2_INSTANCE_NAME="${FRONTEND_PM2_INSTANCE_NAME:-dr-prod-front}"

echo "Variables:"
echo "BACKEND_DIR: ${BACKEND_DIR}"
echo "FRONTEND_DIR: ${FRONTEND_DIR}"
echo "BACKEND_PM2_INSTANCE_NAME: ${BACKEND_PM2_INSTANCE_NAME}"
echo "FRONTEND_PM2_INSTANCE_NAME: ${FRONTEND_PM2_INSTANCE_NAME}"
echo "----------------------"
echo "Starting the script..."

# This function reverts to a previous git version if a backup
# branch has been previously created manually or by other scripts.
function revert_to_previous_version() {
    local path="$1"
    echo "Starting git operations for ${path}"

    # Switch to 'previous-version' branch only if it already exists
    if git -C "${path}" show-ref --verify --quiet refs/heads/previous-version; then
        # Reset any changes so we can switch to another branch below
        git -C "${path}" reset --hard HEAD 
        echo "Switching to the 'previous-version' branch."
        git -C "${path}" checkout previous-version

        # Install npm packages if packages have been changed
        npm install --prefix "${path}"

        # Run 'build' script if it exists in package.json
        local json=$(cat "${path}"/package.json)
        if [[ $json == *"\"build\""* ]]; then
          echo "The 'build' script exists in package.json"
          npm run --prefix "${path}" build
        else
          echo "The 'build' script does not exist in package.json"
        fi

    else
        echo "'previous-version' branch does not exist for:"
        echo "$1"
        echo "Cannot revert to a previous version."
        echo "Try reverting manually, e.g.:"
        echo "git checkout <ID_OF_COMMIT_OF_PREVIOUS_VERSION>"
        echo "You can find a required ID with 'git log --oneline'"
        echo "Don't forget to do that for both backend and frontend,"
        echo "and run 'npm install' in both folders,"
        echo "and build the frontend with 'npm run build'"
        echo "and restart pm2 with 'pm2 restart all'"
    fi
}

revert_to_previous_version "${BACKEND_DIR}"
revert_to_previous_version "${FRONTEND_DIR}"

# Sometimes after 'pm2 delete all' the instances like
# 'prod-back@1.6.1' will show up after running 'pm2 list',
# but we will get an error if trying to delete them like
# 'pm2 delete prod-back@1.6.1'.
# The solution is to force sync the list before deleting
# the old pm2 instances.
pm2 save --force

# Normally, 'pm2 restart all' is enough, but some updates
# require deleting old pm2 instances and spawning new ones.
# Thus, let's use 'pm2 delete' instead.
function delete_pm2_instance() {
  local pm2_instance_name="$1"

  # Check if an instance exists
  if pm2 list | grep -q "${pm2_instance_name}"; then
      pm2 delete "${pm2_instance_name}"
      echo "Instance ${pm2_instance_name} deleted."
  else
      echo "Instance ${pm2_instance_name} not found."
  fi
}

delete_pm2_instance "${BACKEND_PM2_INSTANCE_NAME}"
delete_pm2_instance "${FRONTEND_PM2_INSTANCE_NAME}"

# Delete old versions with the old naming format
delete_pm2_instance "prod-back@1.6.1"
delete_pm2_instance "prod-back@1.6.0"
delete_pm2_instance "prod-back@1.5.0"
delete_pm2_instance "prod-back@1.4.0"
delete_pm2_instance "prod-back@1.3.0"
delete_pm2_instance "prod-back@1.2.0"
delete_pm2_instance "prod-back@1.1.0"
delete_pm2_instance "prod-front@1.6.1"
delete_pm2_instance "prod-front@1.6.0"
delete_pm2_instance "prod-front@1.5.0"
delete_pm2_instance "prod-front@1.4.0"
delete_pm2_instance "prod-front@1.3.0"
delete_pm2_instance "prod-front@1.2.0"
delete_pm2_instance "prod-front@1.1.0"

npm run --prefix "${BACKEND_DIR}" start-prod
npm run --prefix "${FRONTEND_DIR}" start-prod

pm2 save

echo "Done"

# Congrats, the revert operation is done.

# If you will change environment variables, then
# don't forget to run npm build after that, e.g.:
# $ cd ~/apps/degenrocket/frontend && npm run build
# and also restart all pm2 app instances, e.g.:
# $ pm2 restart all
