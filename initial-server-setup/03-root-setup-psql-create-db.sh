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
# export NEEDRESTART_MODE=a
# export DEBIAN_FRONTEND=noninteractive

USER="user"
ADMIN="admin"

POSTGRES_USER="dbuser"
POSTGRES_PASSWORD="dbuser"
POSTGRES_DATABASE="news_database"
POSTGRES_PORT="5432"

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

