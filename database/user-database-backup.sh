#!/bin/bash
# pipefail stops execution if encounters any errors
set -euo pipefail

# Import environment variables:
# USER
# ADMIN
# POSTGRES_USER
# POSTGRES_DATABASE
# POSTGRES_PORT
# ALL_BACKUPS_FOLDER_NAME
# Find the absolute path to this script
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ENV_FILE="${THIS_SCRIPT_DIR}/../.env"
# Source .env file only if it exists
test -f "${ENV_FILE}" && source "${ENV_FILE}"

# Assign a default value if it is unset or empty
USER="${USER:-user}"
ADMIN="${ADMIN:-admin}"
DATABASE_USER="${POSTGRES_USER:-dbuser}"
DATABASE_NAME="${POSTGRES_DATABASE:-spasm_database}"
DATABASE_PORT="${POSTGRES_PORT:-5432}"
ALL_BACKUPS_FOLDER_NAME="${ALL_BACKUPS_FOLDER_NAME:-backups}"

DATABASE_BACKUPS_FOLDER="${ALL_BACKUPS_FOLDER_NAME}/database"
CURRENT_BACKUP_FULL_PATH="${DATABASE_BACKUPS_FOLDER}/${DATABASE_NAME}_$(date +%Y%m%d).sql"

# Create backup folder for admin
bash -c "mkdir -p ${DATABASE_BACKUPS_FOLDER}"

echo "Please type the password for the database user: ${DATABASE_USER}"

# Backup the database, adding the date at the end of a file
pg_dump -h localhost -U "${DATABASE_USER}" "${DATABASE_NAME}" > "${CURRENT_BACKUP_FULL_PATH}" -p "${DATABASE_PORT}"

MY_HOME_DIRECTORY="$(eval echo ~$(whoami))"
echo "${DATABASE_NAME} is saved into:"
echo "${MY_HOME_DIRECTORY}/${CURRENT_BACKUP_FULL_PATH}"

# Use .bak for large databases
# pg_dump ${DATABASE_NAME} > ${BACKUP_FOLDER}/${DATABASE_NAME}.bak
