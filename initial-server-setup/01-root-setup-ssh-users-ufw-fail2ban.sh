#!/bin/bash
# pipefail stops execution if encounters any errors
set -euo pipefail

# Disable Ubuntu 22.04 "Daemon using outdated libraries" prompt
# By setting restart option in /etc/needrestart/needrestart.conf to:
# 'a' if we want to restart the services automatically
# $nrconf{restart} = 'a';
# 'l' if we want to simply list the services that need restart.
# $nrconf{restart} = 'l';
sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
# Another approach to stop prompts (currently disabled): 
# export NEEDRESTART_MODE=a
# export DEBIAN_FRONTEND=noninteractive

USER="user"
ADMIN="admin"
NEW_SSH_PORT="2222"

# By default, SSH keys are only copied to a user without privileges,
# so an adversary will not get a sudo access if SSH keys leak. 
# Thus, a server administrator has to SSH into a user and then
# switch to a password-protected admin in order to get a sudo access.
COPY_SSH_KEYS_FROM_ROOT_TO_USER=true
COPY_SSH_KEYS_FROM_ROOT_TO_ADMIN=false

COPY_SCRIPTS_FROM_ROOT_TO_USER=true
COPY_SCRIPTS_FROM_ROOT_TO_ADMIN=true

################################
############ USERS #############
# Add a user without privileges
useradd --create-home --shell "/bin/bash" "${USER}"
# Set the temporary password for the user
# to be equal to his name, e.g.:
# name: alice, password: alice
echo "${USER}:${USER}" | chpasswd

echo "Created user: ${USER}"
echo "${USER} groups: $(groups ${USER})"
echo "--------"

# Add an admin with privileges
# Privilege group names depend on linux distribution
# 'sudo' and 'admin' on Debian/Ubuntu:
# useradd --create-home --shell "/bin/bash" "${ADMIN}" --groups sudo
# usermod -aG admin "${ADMIN}"
# Changed the order of groups from sudo/admin to admin/sudo to avoid an error:
# useradd: group admin exists - if you want to add this user to that group, use -g.
useradd --create-home --shell "/bin/bash" -g admin "${ADMIN}" 
usermod -aG sudo "${ADMIN}"
# Set the temporary password for the user
# to be equal to his name, e.g.:
# name: alice, password: alice
echo "${ADMIN}:${ADMIN}" | chpasswd

echo "Created user: ${ADMIN}"
echo "${ADMIN} groups: $(groups ${ADMIN})"
echo "--------"

################################
############# SSH ##############
# Create SSH directory for user
user_home_directory="$(eval echo ~${USER})"
mkdir --parents "${user_home_directory}/.ssh"
# Change file ownership from root to user
chown --recursive "${USER}":"${USER}" "${user_home_directory}/.ssh"

# Create SSH directory for admin
# By default, it's not gonna be used
admin_home_directory="$(eval echo ~${ADMIN})"
mkdir --parents "${admin_home_directory}/.ssh"
# Change file ownership from root to admin
chown --recursive "${ADMIN}":"${ADMIN}" "${admin_home_directory}/.ssh"

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

# Copy SSH key from root to admin if requested
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
echo "ssh is backed"

# Change SSH port because many bots scan default port 22.
# Port can be changed to any number between 1024 and 65535.
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
echo "Try to SSH from another terminal before closing this session"
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
echo "--------"

# Custom passwords are currently disabled, because
# they have to be set in the end of the server setup.
# echo "Set a password for ${USER}"
# passwd "${USER}"
# echo "Set a password for ${ADMIN}"
# passwd "${ADMIN}"
