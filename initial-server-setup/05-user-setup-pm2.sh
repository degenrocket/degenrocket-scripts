#!/bin/bash
# pipefail stops execution if encounters any errors
set -euo pipefail

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

bash -c "npm install pm2 -g && pm2 update"

# The command below requires a user interaction, so it's deprecated.
# su - "${USER}" bash -c ". ~/.nvm/nvm.sh && npm install pm2 -g && pm2 update && pm2 startup"

# Explanation on "pm2 startup".
# To make sure that pm2 starts up after a server reboot and brings up
# the frontend and backend of the app, you'd normally run "pm2 startup".
# However, "pm2 startup" requires user's input, because it will provide
# a command that should be copy/pasted into the terminal, example:
# [PM2] To setup the Startup Script, copy/paste the following command:
# sudo env PATH=$PATH:/home/user/.nvm/versions/node/v18.17.1/bin pm2 startup systemd -u user --hp /home/user
# There are two major issues with this approach:
# 1. It requires a user input, which is not ideal for scripting.
# 2. A user that installs pm2 doesn't have sudo privileges.
# Note: if you're an experienced user setting up the server manually
# and you don't want to use cron jobs to restart pm2 after each reboot,
# - then you can simply run "pm2 startup" from a user,
# - copy the provided command,
# - switch to an admin with privileges,
# - then pass the copied command to a user without privileges,
# - execute the final command,
# - and test the pm2 setup by restarting the server.
# The final command will look something like:
# sudo su - user bash -c "env PATH=$PATH:/home/user/.nvm/versions/node/v18.17.1/bin pm2 startup systemd -u user --hp /home/user"
# One more solution is to temporary grant a user with sudo privileges
# to execute "pm2 startup" and run the provided command.

# For an automatic setup via a script we are using another approach.
# We're adding "pm2 resurrect" to a cron job, which will be executed
# after each server reboot. The "pm2 resurrect" command starts all apps
# that were previously saved using "pm2 save".
# Now let's explain the script below.
# "crontab -l" prints all current cron jobs,
# "echo" prints the next line,
# "@reboot" indicates that a line should be executed after each reboot,
# Note: we need to specify full paths to node/pm2 when using cron, so
# "which node" provides a path to node, which is required for pm2,
# "which pm2" provides a path to pm2,
# "resurrect" starts up all apps saved with "pm2 save",
# "| crontab -" saves the printed output into the crontab.
# You can also edit cron jobs manually by executing "crontab -e".

ADD_PM2_TO_CRON="(crontab -l ; echo \"@reboot $(which node) $(which pm2) resurrect\") | crontab -"

bash -c "${ADD_PM2_TO_CRON}"

# List all cron jobs
crontab -l

# Warning: paths to node/pm2 contain a version, so we need to
# update them when packages are updated.
# For example, we can run this script after each node/pm2 update.
# Alternatively, we can create a cron job to update node/pm2 paths hourly.
