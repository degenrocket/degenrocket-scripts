## Initial Server Setup

### Intro

This guide is intended for beginners who wish to run an instance of web3 online forum DegenRocket.

You don't have to follow this guide if you're an experienced sysadmin or you already have a hardened server. Although, it's recommended to run an instance on a separate server for security reasons.

The large portion of the setup is done via custom scripts, so you mostly need to copy-paste commands into a terminal and wait for the installation process to finish with minimum interactions like typing your domain name.

This instruction has been tested on Ubuntu 22.04.3.

Troubleshooting: if you encounter any errors, please create a new issue or send a message to 'degenrocket' on [Session](https://getsession.org).

---

### VPS

##### Rent VPS Ubuntu 22.04.

We recommend using different hosting providers for diversification reasons.
That said, some instances are using privacy-focused domain name registrar
and hosting provider Njalla, established by one of The Pirate Bay founders.

---

### DNS

Configure DNS at the dashboard of your VPS provider.
Add at least 3 records for this script to work without errors:

```
# your_domain.com
# www.your_domain.com
# staging.your_domain.com
```

Choose Type 'A' for IPv4 addresses.

Choose Type 'AAAA' for IPv6 addresses.

Set Name to your domain name.

Set IPv4 to an IP address of your server.

Choose TTL '3h' or leave it as default.

```
# Example:
# Type:A, Name:degenrocket.space, IPv4:20.21.03.01, TTL:3h
# Type:A, Name:www.degenrocket.space, IPv4:20.21.03.01, TTL:3h
# Type:A, Name:staging.degenrocket.space, IPv4:20.21.03.01, TTL:3h
```

Note: if you want to use 'AAAA' to link to an IPv6 address,
then make sure that your firewall allows IPv6.

For example, `IPV6=yes` in `/etc/default/ufw`

---

### SSH

Generate and upload an SSH key to your hosting provider.

```
# Generate SSH key with a comment "YOUR_NAME" on your home machine.
ssh-keygen -t ed25519 -C "YOUR_NAME"
# Example:
ssh-keygen -t ed25519 -C "user"
```

#### Add your SSH .pub to your VPS provider.

On Linux SSH .pub is usually located at `~/.ssh/YOUR_NAME.pub`

Copy the content of `YOUR_NAME.pub` to clipboard with a text editor
or with a `wl-copy` command if wl-clipboard is installed, e.g.:

```
wl-copy < ~/.ssh/user.pub
```

Open your VPS provider and paste your SSH pub key into an SSH box.

If you're testing in VM, then paste into `/root/.ssh/authorized_keys`

Note: it's important to use SSH keys because the password authentication
will be disabled by one of the following setup scripts.

```
# SSH into your server as root
ssh -i ~/.ssh/YOUR_SSH_KEY root@YOUR_SERVER_IP_ADDRESS
# Example:
ssh -i ~/.ssh/user root@20.21.03.01
# Type 'yes' to add the server key fingerprint to your known hosts
```

Try to log in again if you got error 'Broken pipe'. 

If you got another error, then read the troubleshooting section below.

#### SSH Troubleshooting

Clean known hosts after rebuild (optional).

Skip this step if you've never logged into your server before.

Note: if you rebuilt a server, don't forget to clean `known_hosts`
from old key fingerprints before trying to SSH into your server
because your server key fingerprint has changed after rebuild.

```
# '-R' deletes a pub key of your previous server build.
ssh-keygen -R YOUR_SERVER_IP_ADDRESS
# Example:
ssh-keygen -R 20.21.03.01
# Then try to SSH into your server without 'sudo':
ssh -i ~/.ssh/YOUR_SSH_KEY root@YOUR_SERVER_IP_ADDRESS
# Example:
ssh -i ~/.ssh/user root@20.21.03.01

# You should see the following message:
# The authenticity of host 'YOUR_SERVER_IP_ADDRESS' can't be established.
# Are you sure you want to continue connecting?
# Type 'yes'.
# You should be logged into your server.
# Try to log in again if you got error 'Broken pipe'. 
```

---

### About scripts

Please read the following notes before downloading and executing
the scripts for the initial server setup.

**Note 1.**

The first word in the name of the script specifies which user
should run the script (root, admin, user), e.g.:

```
# 03-root-setup-psql-create-db.sh
# 04-admin-setup-ssl.sh
# 05-user-setup-pm2.sh
```

**Note 2.**

If after executing some setup scripts, you've logged out
of the server and cannot log in as a root to continue,
then try to log in as a `user` with port `2222`, e.g.:

```
ssh -i ~/.ssh/user user@20.21.03.01 -p 2222
# Don't forget to change 20.21.03.01 to your server IP address

# then switch to an admin (default password: admin)
su - admin

# then switch to root (use password of an admin, default: admin)
sudo su - root
```

**Note 3.**

Certain errors might stop the execution of some of the scripts.

In that case you should try to run the same script again.

However, some scripts cannot be executed multiple times due to
`set -euo pipefail` option.

Thus, you can try do delete that line and run the script again.

If that doesn't help, then try to rebuild the server from scratch.

---

### Root setup

You should be logged in as `root`, so you can run setup scripts.

Download all scripts manually into `/root/scripts/` or using `git clone`.

```
mkdir scripts
git clone https://github.com/degenrocket/degenrocket-scripts.git scripts/
```

Look through all downloaded scripts and compare them to the source
to make sure that you didn't download anything malicious.

```
# Example:
nano scripts/initial-server-setup/01-root-setup-ssh-users-ufw-fail2ban.sh
```

#### Execute scripts 01, 02, 03 from `root`.

```
bash scripts/initial-server-setup/01-root-setup-ssh-users-ufw-fail2ban.sh
```

The script above will:
* Create a user without privileges
* Set a password for a user (default: user)
* Create an admin with privileges
* Set a password for an admin (default: admin)
* Copy authorized SSH keys from root to a user
* Change SSH port (default new port: 2222)
* Disable SSH root login
* Disable SSH password authentication
* Configure UFW firewall to allow SSH, ftp, http, https
* Install and enable fail2ban

```
bash scripts/initial-server-setup/02-root-setup-apt-postgres-npm-nginx.sh
```

The script above will:
* Update the operating system
* Install and configure postgresql
* Install NVM
* Update npm
* Install required node version
* Install and configure Nginx

```
bash scripts/initial-server-setup/03-root-setup-psql-create-db.sh
```

The script above will:
* Create a new postgres user (default: dbuser)
* Set a password for a new user (default: dbuser)
* Create a new database (default: news_database) owned by a new user 
* Create required database tables

---

### Admin setup

Switch to an admin to execute the next script.

```
# Default password is 'admin'.
su - admin
```

There should already be a folder with latest scripts.

If not, copy-paste the script manually or use `git clone`, and then execute:

```
sudo bash scripts/initial-server-setup/04-admin-setup-ssl.sh
```

Note: this script requires sudo (default password: admin)

The script above will:
* Ask for your domain name (e.g., degenrocket.space)
* Install snapd
* Install Letsencrypt's certbot
* Request an SSL certificate (for HTTPS connection)
* Test auto-renewal of a certificate


---

### User setup

Now switch to a user to execute final scripts.

```
# Default password is 'user'.
su - user
```

There should already be a folder with scripts.

If not, copy-paste the script manually or use `git clone`, and then execute:

```
bash scripts/initial-server-setup/05-user-setup-pm2.sh
```

The script above will:
* Install pm2
* Add `pm2 resurrect` to cron jobs to start apps after each reboot

Next, we can finally instal the app.

```
bash scripts/initial-server-setup/06-user-setup-git.sh
```

The following script will:
* Create folders to download the app
* Download the app with git
* Install dependencies

---

### Customize the app

Adjust `backend/.env` if you've changed default database user or password

```
nano ~/apps/degenrocket/backend/.env
```

Set app name, social media links and other options in `frontend/.env`

```
nano ~/apps/degenrocket/frontend/.env
```

Make sure `API_URL` is set properly in `frontend/.env`

Some examples:

```
# Production with SSL certificate (https) and Nginx
API_URL=https://degenrocket.space
# Testing in VM with Nginx (port forwarding)
API_URL=http://192.168.122.200
# Testing locally without Nginx
API_URL=http://localhost:5000
```

Copy-paste your logos into the `public/` folder with following names.

(recommented sizes are 100x100, 192x192, 512x512) 

```
frontend/public/favicon.ico
frontend/public/pwa-192x192.png
frontend/public/pwa-512x512.png
```

There are different ways how to upload files to the server.

##### Upload with SFTP

Open the folder on your **home machine** that contains logos, e.g.:

```shell
cd ~/Documents/degenrocket/mylogos
```

Create an SFTP connection with your server

```shell
sftp -P YOUR_PORT -i ~/.ssh/YOUR_SSH_KEY user@YOUR_SERVER_IP_ADDRESS
# Example:
sftp -P 2222 -i ~/.ssh/user user@20.21.03.01
```

*Note: SSH uses `-p`, while SFTP uses capital `-P` to specify a custom port.
The location of `-P` is also important because you cannot add it at the end
of the command after the destination address like when using SSH.*

After logging into your server, choose the destination folder for logos

```shell
cd apps/degenrocket/frontend/public
```

Verify that you're in the right folder with `pwd`

```shell
pwd
```

The output should look something like this:

```shell
Remote working directory: /home/user/apps/degenrocket/frontend/public
```

Copy all files from home `mylogos` folder to server `public` folder

```shell
put *
```

Alternatively, you can copy files one by one

```shell
put favicon.ico
put pwa-192x192.png
put pwa-512x512.png
```

Check that all necessary logos were copied with `ls -1`

```shell
ls -1
```

At the time of writing this guide, the current version of the app
contains examples and logos in the `public` folder, so the output of
`ls -1` after transferring custom logos looks like this: 

```shell
favicon.example.ico
favicon.ico
logos
pwa-192x192.example.png
pwa-192x192.png
pwa-512x512.example.png
pwa-512x512.png
```

Close the SFTP connection

```shell
exit
```
---

### Run the app

SSH into a server as a user or switch to a user

```shell
su - user
```
 
```shell
# Start the backend
cd ~/apps/degenrocket/backend && npm run prod && cd ~/
# Build and then start the frontend
cd ~/apps/degenrocket/frontend && npm run build && npm run prod && cd ~/
```

```shell
# Check running apps
pm2 list

# Save running apps so they auto-start after each system reboot
pm2 save
```

---

### Test the app

Go to your domain or IP address in the browser and test the app.

There are no default posts in database, so try to create a new post.

Troubleshooting: after getting an SSL certificate, don't forget
to set a proper `https` API domain in `frontend/.env`.

Finally, reboot the system to test pm2 auto-startup.
The app should automatically start after reboot.

```
systemctl reboot -i
```

*Warning: rebooting the system will log you out of the server,
so it's recommended to test your SSH connection from another
terminal before rebooting the system.
If you lock yourself out of the system without any chance to log in,
you'll need to rebuild the server and start the setup process again.*

---

### Passwords

**IMPORTANT!**

```
# SSH into the server as a user
# Switch to an admin (default password: admin)
su - admin

# Change passwords for a user and admin
sudo passwd user
sudo passwd admin
```

---

### Home machine

**Test SSH**

It's recommended to SSH into the server from another terminal,
so you can troubleshoot your SSH configuration if you won't be able
to log in as a user with a new port.

You have to speficy a new SSH port (default: `2222`)
and a new user, because root login is disabled.

Example:

```
# Don't forget to change '20.21.03.01' to your server IP address
ssh -i ~/.ssh/user user@20.21.03.01 -p 2222
```

You can also add this to `~/.ssh/config` on your home machine:

```
# Don't forget to change '20.21.03.01' to your server IP address
Host my-server
  Hostname 20.21.03.01
  Port 2222
  User user
```

You should now be able to SSH into your server with this command:

```
ssh my-server
```
