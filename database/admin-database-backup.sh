#!/bin/bash
# pipefail stops execution if encounters any errors
# set -euo pipefail

USER="user"
ADMIN="admin"
DATABASE_NAME=news_database

ALL_BACKUPS_FOLDER="backups"
DATABASE_BACKUPS_FOLDER="${ALL_BACKUPS_FOLDER}/database"
CURRENT_BACKUP_FULL_PATH="${DATABASE_BACKUPS_FOLDER}/${DATABASE_NAME}_$(date +%Y%m%d).sql"

# Create backup folder for admin
bash -c "mkdir -p ${DATABASE_BACKUPS_FOLDER}"

# Backup the database, adding the date at the end of a file
pg_dump ${DATABASE_NAME} > ${CURRENT_BACKUP_FULL_PATH}

USER_HOME_DIRECTORY="$(eval echo ~${USER})"
sudo mkdir --parents "${USER_HOME_DIRECTORY}/${DATABASE_BACKUPS_FOLDER}"

# Copy a backup from an admin folder to a user folder
# so you can easily download it via sftp.
sudo cp ${CURRENT_BACKUP_FULL_PATH} ${USER_HOME_DIRECTORY}/${CURRENT_BACKUP_FULL_PATH}
# Change file ownership from admin to user
sudo chown --recursive "${USER}":"${USER}" "${USER_HOME_DIRECTORY}/${ALL_BACKUPS_FOLDER}"

MY_HOME_DIRECTORY="$(eval echo ~$(whoami))"
echo "${DATABASE_NAME} is saved into two locations:"
echo "${MY_HOME_DIRECTORY}/${CURRENT_BACKUP_FULL_PATH}"
echo "${USER_HOME_DIRECTORY}/${CURRENT_BACKUP_FULL_PATH}"

# Use .bak for large databases
# pg_dump ${DATABASE_NAME} > ${BACKUP_FOLDER}/${DATABASE_NAME}.bak

