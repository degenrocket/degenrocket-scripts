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
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive

# Import environment variables:
# USER_NAME
# ADMIN_NAME
# POSTGRES_USER
# POSTGRES_DATABASE
# POSTGRES_PORT
# Find the absolute path to this script
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ENV_FILE="${THIS_SCRIPT_DIR}/../.env"
# Source .env file only if it exists
test -f "${ENV_FILE}" && source "${ENV_FILE}"

# Assign a default value if it is unset or empty
USER="${USER_NAME:-user}"
ADMIN="${ADMIN_NAME:-admin}"
POSTGRES_USER="${POSTGRES_USER:-dbuser}"
POSTGRES_DATABASE="${POSTGRES_DATABASE:-spasm_database}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_DATABASE_TEST="${POSTGRES_DATABASE}_test"

# Temporary set a password to be equal to a database username,
# it should be manually changed after the initial server setup.
# Default password: dbuser
POSTGRES_PASSWORD="${POSTGRES_USER:-dbuser}"

echo "Variables:"
echo "USER: ${USER}"
echo "ADMIN: ${ADMIN}"
echo "POSTGRES_USER: ${POSTGRES_USER}"
echo "POSTGRES_DATABASE: ${POSTGRES_DATABASE}"
echo "POSTGRES_PORT: ${POSTGRES_PORT}"
echo "POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}"
echo "----------------------"
echo "Starting the script..."

# Create a new postgres account without superuser privileges
# and then grant that account one privilege to create
# new databases, which will be used by other scripts.
su - postgres bash -c "psql -c \"CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}'; ALTER USER ${POSTGRES_USER} CREATEDB;\""

# su - postgres bash -c "psql -c \"
# IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '''${POSTGRES_USER}''') THEN
# CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}'; ALTER USER ${POSTGRES_USER} CREATEDB;
# \""

# su - postgres bash -c "psql -c \"BEGIN; IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '''${POSTGRES_USER}''') THEN CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}'; ALTER USER ${POSTGRES_USER} CREATEDB; END IF; \""

# Create SQL script content
# SQL_SCRIPT=$(cat <<EOF
# BEGIN;
# DECLARE
#     user_exists boolean;
# BEGIN
#     SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '''${POSTGRES_USER}''') INTO user_exists;
#
#     IF NOT user_exists THEN
#         CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';
#         ALTER USER ${POSTGRES_USER} CREATEDB;
#     END IF;
# COMMIT;
# EOF
# )

# su - postgres bash -c "psql -c '${SQL_SCRIPT}'"

# Create database
su - postgres bash -c "psql -c \"CREATE DATABASE ${POSTGRES_DATABASE} WITH OWNER = ${POSTGRES_USER};\""

# Create database for running tests
su - postgres bash -c "psql -c \"CREATE DATABASE ${POSTGRES_DATABASE_TEST} WITH OWNER = ${POSTGRES_USER};\""

# Create tables
CREATE_TABLES_SQL="
CREATE TABLE posts (
    id SERIAL NOT NULL,
    guid TEXT NOT NULL PRIMARY KEY,
    source TEXT,
    category TEXT,
    tickers TEXT,
    tags TEXT,
    title TEXT,
    url TEXT,
    description TEXT,
    pubdate TIMESTAMPTZ
);
CREATE TABLE actions (
    id SERIAL NOT NULL,
    target TEXT NOT NULL,
    action TEXT,
    category TEXT,
    tags TEXT,
    tickers TEXT,
    title TEXT,
    text TEXT,
    signer TEXT,
    signed_message TEXT,
    signature TEXT,
    signed_time TIMESTAMPTZ,
    added_time TIMESTAMPTZ
);
CREATE TABLE actions_count (
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
);
CREATE TABLE spasm_events (
    spasm_event JSONB,
    stats JSONB,
    shared_by JSONB,
    db_key SERIAL PRIMARY KEY NOT NULL,
    db_added_timestamp BIGINT,
    db_updated_timestamp BIGINT
);
CREATE TABLE spasm_users (
    spasm_user JSONB,
    db_key SERIAL PRIMARY KEY NOT NULL,
    db_added_timestamp BIGINT,
    db_updated_timestamp BIGINT
);
CREATE TABLE spasm_sources (
    spasm_source JSONB,
    db_key SERIAL PRIMARY KEY NOT NULL,
    db_added_timestamp BIGINT,
    db_updated_timestamp BIGINT
);
CREATE TABLE rss_sources (
    rss_source JSONB,
    db_key SERIAL PRIMARY KEY NOT NULL,
    db_added_timestamp BIGINT,
    db_updated_timestamp BIGINT
);
CREATE TABLE extra_items (
    extra_item JSONB,
    db_key SERIAL PRIMARY KEY NOT NULL,
    db_added_timestamp BIGINT,
    db_updated_timestamp BIGINT
);
CREATE TABLE admin_events (
    spasm_event JSONB,
    db_key SERIAL PRIMARY KEY NOT NULL,
    db_added_timestamp BIGINT,
    db_updated_timestamp BIGINT
);
CREATE TABLE app_configs (
    spasm_event JSONB,
    db_key SERIAL PRIMARY KEY NOT NULL,
    db_added_timestamp BIGINT,
    db_updated_timestamp BIGINT
);
CREATE INDEX spasm_events_event_idx ON spasm_events USING GIN (spasm_event);
CREATE INDEX spasm_events_stats_idx ON spasm_events USING GIN (stats);
CREATE INDEX spasm_users_user_idx ON spasm_users USING GIN (spasm_user);
CREATE INDEX spasm_sources_source_idx ON spasm_sources USING GIN (spasm_source);
CREATE INDEX rss_sources_source_idx ON rss_sources USING GIN (rss_source);
CREATE INDEX extra_items_item_idx ON extra_items USING GIN (extra_item);
CREATE INDEX admin_events_event_idx ON admin_events USING GIN (spasm_event);
CREATE INDEX app_configs_event_idx ON app_configs USING GIN (spasm_event);
"

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

su - postgres bash -c "env PGPASSWORD=\"${POSTGRES_PASSWORD}\" psql -h localhost -d ${POSTGRES_DATABASE_TEST} -U ${POSTGRES_USER} -p ${POSTGRES_PORT} -c \"$CREATE_TABLES_SQL\""

# You can test postgresql connection for user 'dbuser' with:
# psql -h localhost -d spasm_database -U dbuser -p 5432
# Then list all tables:
# \dt
# Check query:
# SELECT * FROM actions;

echo "Success. End of script."
