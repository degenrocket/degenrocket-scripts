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
# Another approach to stop prompts (currently disabled): 
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive

# Import environment variables:
# USER
# ADMIN
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
POSTGRES_USER="${POSTGRES_USER:-dbuser}"
POSTGRES_DATABASE="${POSTGRES_DATABASE:-news_database}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

# Temporary set a password to be equal to a database username,
# it should be manually changed after the initial server setup.
# Default password: dbuser
POSTGRES_PASSWORD="${POSTGRES_USER:-dbuser}"

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
echo "POSTGRES_USER: ${POSTGRES_USER}"
echo "POSTGRES_DATABASE: ${POSTGRES_DATABASE}"
echo "POSTGRES_PORT: ${POSTGRES_PORT}"
echo "POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}"
echo "----------------------"
echo "Starting the script..."

# Create postgres account for admin without privileges
su - postgres bash -c "psql -c \"CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';\""

# Create database
su - postgres bash -c "psql -c \"CREATE DATABASE ${POSTGRES_DATABASE} WITH OWNER = ${POSTGRES_USER};\""

# Create tables
CREATE_TABLES_SQL="CREATE TABLE IF NOT EXISTS posts(
id SERIAL NOT NULL,
guid TEXT NOT NULL PRIMARY KEY,
source TEXT,
category TEXT,
tickers TEXT,
title TEXT,
url TEXT,
description TEXT,
pubdate TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS actions(
id SERIAL NOT NULL,
target TEXT NOT NULL,
action TEXT,
category TEXT,
title TEXT,
text TEXT,
signer TEXT,
signed_message TEXT,
signature TEXT,
signed_time TIMESTAMPTZ,
added_time TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS public.actions_count(
target text NOT NULL,
upvote integer,
downvote integer,
bullish integer,
bearish integer,
important integer,
scam integer,
comments_count integer,
latest_action_added_time TIMESTAMPTZ,
PRIMARY KEY (target)
);"

# The PGPASSWORD environment variable is used by
# the psql command to authenticate the user.
# export PGPASSWORD="${POSTGRES_PASSWORD}"
# However, simply exporting a variable won't work because it will be
# exported for a 'root' user, but the SQL command will be executed by
# the 'postgres' user, which won't get the environment variable.
# Thus, we can use 'env' to pass the password to the 'postres' user.
# 1. Log in as a 'postgres' user,
# 2. Execute bash script,
# 3. Pass the postgres user password as an environment variable,
# 4. Connect to the database as a new user with the port.
# 5. Execute the SQL command to create a table.
su - postgres bash -c "env PGPASSWORD=\"${POSTGRES_PASSWORD}\" psql -h localhost -d ${POSTGRES_DATABASE} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -c \"$CREATE_TABLES_SQL\""

# You can test postgresql connection for user 'dbuser' with:
# psql -h localhost -d news_database -U dbuser -p 5432
# Then list all tables:
# \dt
# Check query:
# SELECT * FROM actions;

