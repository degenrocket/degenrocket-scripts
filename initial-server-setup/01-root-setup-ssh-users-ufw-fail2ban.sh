#!/bin/bash
# pipefail stops execution if encounters any errors
set -euo pipefail

# Disable Ubuntu 22.04 "Daemon using outdated libraries" prompt
# By setting restart option in /etc/needrestart/needrestart.conf to:
# 'a' if we want to restart the services automatically
# $nrconf{restart} = 'a';
# 'l' if we want to simply list the services that need restart.
# $nrconf{restart} = 'l';
# sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
# Another approach to stop prompts (currently disabled): 
export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive

# Import environment variables:
# USER_NAME
# ADMIN_NAME
# NEW_SSH_PORT
# Find the absolute path to this script
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ENV_FILE="${THIS_SCRIPT_DIR}/../.env"
# Source .env file only if it exists
test -f "${ENV_FILE}" && source "${ENV_FILE}"

# Assign a default value if it is unset or empty
USER="${USER_NAME:-user}"
ADMIN="${ADMIN_NAME:-admin}"
NEW_SSH_PORT="${NEW_SSH_PORT:-2222}"

echo "Variables:"
echo "USER: ${USER}"
echo "ADMIN: ${ADMIN}"
echo "NEW_SSH_PORT: ${NEW_SSH_PORT}"
echo "----------------------"
echo "Starting the script..."

# By default, SSH keys are only copied to a user without privileges,
# so an adversary will not get a sudo access if SSH keys leak. 
# Thus, a server administrator has to SSH into a user and then
# switch to a password-protected admin in order to get a sudo access.
COPY_SSH_KEYS_FROM_ROOT_TO_USER=true
COPY_SSH_KEYS_FROM_ROOT_TO_ADMIN=false

COPY_SCRIPTS_FROM_ROOT_TO_USER=true
COPY_SCRIPTS_FROM_ROOT_TO_ADMIN=true

################################
########### GROUPS #############
# Create 'admin' group if it doesn't exist
if getent group admin >/dev/null
then
    echo "Group 'admin' already exists."
else
    echo "Group 'admin' does not exist. Creating it now."
    sudo groupadd admin
    # Add the group to the sudoers file
    echo "Adding 'admin' group to sudoers file"
    echo "%admin ALL=(ALL:ALL) ALL" | sudo EDITOR='tee -a' visudo
fi

################################
############ USERS #############
# USER
# Add a user without privileges
# Check if user already exists
if id -u "${USER}" >/dev/null 2>&1; then
    echo "User ${USER} already exists."
else
    useradd --create-home --shell "/bin/bash" "${USER}"
    echo "Created user: ${USER}"
    # Set the temporary password for user
    # to be equal to his name, e.g.:
    # name: user, password: user
    echo "${USER}:${USER}" | chpasswd
fi

echo "${USER} groups are: $(groups ${USER})"
echo "--------"

# ADMIN
# Add an admin with privileges
# Privilege group names depend on linux distribution
# 'sudo' and 'admin' on Debian/Ubuntu:

# Check if admin already exists
if id -u "${ADMIN}" >/dev/null 2>&1; then
    echo "User ${ADMIN} already exists."
else
    # Changed the order of groups from sudo/admin to admin/sudo to avoid an error:
    # ERROR: useradd: group admin exists - if you want to add this user to that group, use -g.
    # Old order:
    # useradd --create-home --shell "/bin/bash" "${ADMIN}" --groups sudo
    # usermod -aG admin "${ADMIN}"
    # New order:
    useradd --create-home --shell "/bin/bash" -g admin "${ADMIN}" 
    usermod -aG sudo "${ADMIN}"
    echo "Created user: ${ADMIN}"
    # Set the temporary password for admin
    # to be equal to his name, e.g.:
    # name: admin, password: admin
    echo "${ADMIN}:${ADMIN}" | chpasswd
fi

# If admin name is not 'admin', but something else (e.g. 'bob'),
# then we need to add 'bob' to a group 'bob' for other scripts
# to work properly, especially commands like 'chown bob:bob file'.
# Add admin to a group with his name.
# Check if admin is already in the group with his name
if getent group "${ADMIN}" | grep -qw "${ADMIN}"; then
    echo "${ADMIN} is already in the group '${ADMIN}'"
else
    echo "${ADMIN} is not in the group '${ADMIN}'"

    echo "Creating a group called '${ADMIN}'..."

    # Create a group with same name as admin if it doesn't exist
    if getent group "${ADMIN}" >/dev/null
    then
        echo "Group '${ADMIN}' already exists."
    else
        echo "Group '${ADMIN}' does not exist. Creating it now."
        sudo groupadd "${ADMIN}"
    fi

    # add admin to the group with the same name
    usermod -aG ${ADMIN} ${ADMIN}
    echo "${ADMIN} has been added to the group '${ADMIN}'"
fi

echo "${ADMIN} groups are: $(groups ${ADMIN})"
echo "--------"

################################
############# SSH ##############
# Create SSH directory for user
user_home_directory="$(eval echo ~${USER})"
mkdir --parents "${user_home_directory}/.ssh"
# Change file ownership from root to user
chown --recursive "${USER}":"${USER}" "${user_home_directory}/.ssh"
echo "SSH directory for ${USER} is created at: ${user_home_directory}/.ssh"

# Create SSH directory for admin
# By default, it's not gonna be used
admin_home_directory="$(eval echo ~${ADMIN})"
mkdir --parents "${admin_home_directory}/.ssh"
# Change file ownership from root to admin
chown --recursive "${ADMIN}":"${ADMIN}" "${admin_home_directory}/.ssh"
echo "SSH directory for ${ADMIN} is created at: ${admin_home_directory}/.ssh"

# Copy SSH key from root to user if requested above
if [ "${COPY_SSH_KEYS_FROM_ROOT_TO_USER}" = true ]; then
    cp /root/.ssh/authorized_keys "${user_home_directory}/.ssh"
    # Adjust SSH files permissions
    chmod 0700 "${user_home_directory}/.ssh"
    chmod 0600 "${user_home_directory}/.ssh/authorized_keys"
    # Change file ownership from root to user
    # chown "${USER}" "${user_home_directory}/.ssh/authorized_keys"
    # chgrp "${USER}" "${user_home_directory}/.ssh/authorized_keys"
    chown --recursive "${USER}":"${USER}" "${user_home_directory}/.ssh"
fi

# Copy SSH key from root to admin if requested above
if [ "${COPY_SSH_KEYS_FROM_ROOT_TO_ADMIN}" = true ]; then
    cp /root/.ssh/authorized_keys "${admin_home_directory}/.ssh"
    # Adjust SSH files permissions
    chmod 0700 "${admin_home_directory}/.ssh"
    chmod 0600 "${admin_home_directory}/.ssh/authorized_keys"
    # Change file ownership from root to admin
    chown --recursive "${ADMIN}":"${ADMIN}" "${admin_home_directory}/.ssh"
fi

echo "SSH keys are copied"

# Lock root (the password will no longer work to grant access)
passwd -l root
echo "root is locked"

# Back up SSH config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
echo "SSH config is backed to /etc/ssh/sshd_config.bak"

# Change SSH port because many bots scan default port 22.
# Port can be changed to a number between 1024 and 65535.
# Make sure a new port doesn't overlap with ports used by
# other services. Check used ports with 'netstat -tuln'.
# Disable root login and password authentication.
echo "Port ${NEW_SSH_PORT}" >> /etc/ssh/sshd_config
echo "SSH port is changed"
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "SSH root login disabled"
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "SSH password authentication disabled"

# Clean extra config /etc/ssh/sshd_config.d/50-cloud-init.conf
# so it doesn't include "PasswordAuthentication yes"
echo "" > /etc/ssh/sshd_config.d/50-cloud-init.conf

service sshd restart
echo "SSH is configured"
echo "--------"

################################
########### SCRIPTS ############
# Copy scripts from root to user if requested above
if [ "${COPY_SCRIPTS_FROM_ROOT_TO_USER}" = true ]; then
    cp /root/scripts/ -r "${user_home_directory}/scripts/"
    # Change file ownership from root to user
    chown --recursive "${USER}":"${USER}" "${user_home_directory}/scripts"
    echo "Scripts are copied to ${user_home_directory}/scripts"
fi

# Copy scripts from root to admin if requested
if [ "${COPY_SCRIPTS_FROM_ROOT_TO_ADMIN}" = true ]; then
    cp /root/scripts/ -r "${admin_home_directory}/scripts/"
    # Change file ownership from root to admin
    chown --recursive "${ADMIN}":"${ADMIN}" "${admin_home_directory}/scripts"
    echo "Scripts are copied to ${admin_home_directory}/scripts"
fi


################################
########### FIREWALL ###########
apt-get -y install ufw
# Configure firewall
sudo ufw allow ${NEW_SSH_PORT}/tcp comment 'SSH'
sudo ufw allow ssh comment 'ssh'
sudo ufw allow 21 comment 'ftp'
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow http comment 'http'
sudo ufw allow https comment 'https'
echo "UFW rules are added"
# with '--force' a user doesn't have to type 'y'
sudo ufw --force enable
echo "UFW is configured and enabled"
echo "--------"

################################
########### FAIL2BAN ###########
# Fail2Ban
apt-get -y install fail2ban

systemctl enable fail2ban

# 'enable' sometimes doesn't work, so added 'restart'
systemctl restart fail2ban

systemctl status fail2ban

# Fail2Ban saves failed authentication attempts in the system logs,
# typically in /var/log/auth.log or /var/log/secure.
# It scans these logs for patterns and
# applies the configured rules to ban IP addresses.
echo "Fail2Ban is configured and enabled"
echo "Try to SSH from another terminal before closing this session"
echo "--------"

# Custom passwords are currently disabled, because
# they have to be set in the end of the server setup.
# echo "Set a password for ${USER}"
# passwd "${USER}"
# echo "Set a password for ${ADMIN}"
# passwd "${ADMIN}"
