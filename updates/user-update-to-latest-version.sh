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

function git_operations() {
    local path="$1"

    echo "Starting git operations for ${path}"

    # Make sure we're on a master branch
    git -C "$path" reset --hard HEAD && git -C "$path" checkout master

    # Reset local changes to master so we can compare it with
    # the remote master branch in the next step 
    git -C "$path" reset --hard HEAD 

    ############################################################
    ################### MAKE BACKUP BRANCH #####################
    # We should not overwrite a backup branch if the local repo
    # is the same as the remote repo, e.g. if a user has already
    # executed this scripts twice.
    # Update local git with info about commits in remote repo
    git -C "$path" fetch

    # Compare the local repository with the remote one
    # local git_status=$(git -C ${path} status)
    # if [[ $git_status != *"Your branch is up to date"* ]];
    local git_diff="$(git -C ${path} diff origin/master)"
    if [ "$git_diff" != "" ]; then
        echo "The local repo is different from the remote repo."
        echo "Let's make the local backup branch called 'previous-version'."

        # Delete the 'previous-version' branch only if it already exists
        if git -C "$path" show-ref --verify --quiet refs/heads/previous-version; then
            echo "The 'previous-version' branch already exists."
            echo "Deleting old 'previous-version' branch."
            git -C "$path" branch -D previous-version
        else
            echo "The 'previous-version' branch does not exist yet."
        fi

        # Create a new backup
        echo "Creating a new backup branch 'previous-version'."
        git -C "$path" branch previous-version
    else
      echo "Your local repo is already the same as the remote repo,"
      echo "so there is no need to create a backup branch from it."
    fi

    # Make sure we are on the master branch
    git -C "$path" reset --hard HEAD && git -C "$path" checkout master

    # Delete any local git changes to master and download a new version
    git -C "$path" reset --hard HEAD && git -C "$path" pull
}

git_operations "${BACKEND_DIR}"
git_operations "${FRONTEND_DIR}"

function env_operations() {
    local path="$1"
    echo "Starting env operations for ${path}"

    local env="${path}/.env"
    local env_bak="${path}/.env.bak"
    local env_example="${path}/.env.example"

    echo "Make .env backup to: ${env_bak}"
    echo "Copying from env: ${env}"
    echo "Copying to env: ${env_bak}"
    cp "${env}" "${env_bak}"

    echo "Copy an example env to a regular env"
    echo "Copying from env: ${env_example}"
    echo "Copying to env: ${env}"
    cp "${env_example}" "${env}"

    # Now we need to merge values from the backup env
    # into a new env which is made from the example env.
    # The function below works properly if the environment
    # variables from the original env file contain only
    # one-line values.
    # Thus, the usage of multi line values is discouraged. 
    local env_from="${env_bak}"
    local env_to="${env}"

    echo "Merging from: ${env_bak}"
    echo "Merging to: ${env}"

    while IFS= read -r line; do
        if [[ "$line" =~ ^# || -z "$line" ]]; then
            # Skip comments and empty lines
            continue
        fi
        # Sometimes a value of an environment variable contains symbol "=",
        # so there are multiple "=" symbols on one line.
        # Thus, we need to extract key and value based on the first '='.
        # Key is the shortest string before '='.
        key="${line%%=*}"
        # Value is the longest string after '='.
        value="${line#*=}"
        # Update the value in the destination file
        sed -i "/^$key=/c\\$key=$value" "${env_to}"
    done < "${env_from}"
}

env_operations "${BACKEND_DIR}"
env_operations "${FRONTEND_DIR}"

function npm_operations() {
    local path="$1"

    echo "Starting npm operations for ${path}"

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
}

npm_operations "${BACKEND_DIR}"
npm_operations "${FRONTEND_DIR}"

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

npm run --prefix "${BACKEND_DIR}" prod
npm run --prefix "${FRONTEND_DIR}" prod

pm2 save

echo "Done"

# Congrats, the update is done.

# If you will change environment variables, then
# don't forget to run npm build after that, e.g.:
# $ cd ~/apps/degenrocket/frontend && npm run build
# and also restart all pm2 app instances, e.g.:
# $ pm2 restart all
