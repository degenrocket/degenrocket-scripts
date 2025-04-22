## Initial Server Setup

### Intro

This guide is intended for beginners who wish to run an instance of web3 online forum DegenRocket.

You don't have to follow this guide if you're an experienced sysadmin or you already have a hardened server. Although, it's recommended to run an instance on a separate server for security reasons.

The large portion of the setup is done via custom scripts, so you mostly need to copy-paste commands into a terminal and wait for the installation process to finish with minimum interactions like typing your domain name.

This instruction has been tested on **Ubuntu 24.04.2**.

Troubleshooting: if you encounter any errors, please create a new issue or send a message to `degenrocket` on [Session](https://getsession.org).

---

### SSH

Generate an SSH key to log into your server without a password.

```shell
# Generate SSH key with a comment "YOUR_NAME" on your home machine.
ssh-keygen -t ed25519 -C "YOUR_NAME"
# Example:
ssh-keygen -t ed25519 -C "user"
```

---

### VPS

##### Rent Virtual Private Server (VPS)

We recommend using different hosting providers for diversification reasons.
That said, some instances are using privacy-focused domain name registrar
and hosting provider Njalla, established by one of The Pirate Bay founders.

Configurations:

- Ubuntu 24.04

- You can choose as low as **1 core CPU** and **1 GB RAM**.

##### Add your SSH .pub to your VPS provider

Upload the SSH key generated above into the SSH form while setting up
your server, so you can log into the server without a password.

On Linux SSH .pub is usually located at `~/.ssh/YOUR_NAME.pub`

Manually copy the content of `YOUR_NAME.pub` to clipboard
using a text editor, e.g.:

```shell
nano ~/.ssh/user.pub
```

Or from the terminal, e.g.:

```shell
cat ~/.ssh/user.pub
```

Or with a `wl-copy` command if wl-clipboard is installed, e.g.:

```shell
wl-copy < ~/.ssh/user.pub
```

Open your VPS provider and paste your SSH pub key into an SSH form.

*Note: it's important to use SSH keys because the password authentication
will be disabled by one of the following setup scripts.*

##### Testing in VM

If you're testing the app locally in a virtual machine (VM),
then paste your SSH key into `/root/.ssh/authorized_keys`

##### SSH into your server

Once your server is built by the VPS provider, you can try to log into it.

```shell
# SSH into your server as root
ssh -i ~/.ssh/YOUR_SSH_KEY root@YOUR_SERVER_IP_ADDRESS
# Example:
ssh -i ~/.ssh/user root@20.21.03.01
```

You should get the following message, type `yes` and press enter
to add the server key fingerprint to your known hosts.

```
The authenticity of host 'YOUR_SERVER_IP_ADDRESS' can't be established.
ED25519 key fingerprint is SHA256:YOUR_SERVER_FINGERPRINT.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
```

Sometimes your connection might be closed:

```
Warning: Permanently added 'YOUR_SERVER_IP_ADDRESS' (ED25519) to the list of known hosts.
Connection closed by YOUR_SERVER_IP_ADDRESS port 22
```

Simply try to log in again with the same command.

```shell
# Example:
ssh -i ~/.ssh/user root@20.21.03.01
```

*Note: try to log in again if you got error 'Broken pipe'.*

If you got another error, then read the troubleshooting section below.

#### SSH Troubleshooting

**Clean known hosts after rebuild**

*Note: skip this step if you've never logged into your server before.*

Sometimes you can mess up the setup process, so it might be easier
to rebuild your server and start the setup process from the scratch.
However, you'll get an error when trying to SSH into a server that
has been recently rebuilt.

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ED25519 key sent by the remote host is
SHA256:YOUR_SERVER_FINGERPRINT.
Please contact your system administrator.
```

In that case, don't forget to clean the `~/.ssh/known_hosts` file
from old key fingerprints before trying to SSH into your server
because your server key fingerprint has changed after rebuild.

```shell
# '-R' deletes a pub key of your previous server build.
ssh-keygen -R YOUR_SERVER_IP_ADDRESS
# Example:
ssh-keygen -R 20.21.03.01
```

Then try to SSH into your server without `sudo`:

```shell
# SSH into your server as root
ssh -i ~/.ssh/YOUR_SSH_KEY root@YOUR_SERVER_IP_ADDRESS
# Example:
ssh -i ~/.ssh/user root@20.21.03.01
```

You should get the following message, type `yes` and press enter
to add the server key fingerprint to your known hosts.

```
The authenticity of host 'YOUR_SERVER_IP_ADDRESS' can't be established.
ED25519 key fingerprint is SHA256:YOUR_SERVER_FINGERPRINT.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
```

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

*Note: if you cannot set your domain name (e.g. 'degenrocket.space')
as name, then try using '@' for root.*

*Note: if you want to use 'AAAA' to link to an IPv6 address,
then make sure that your firewall allows IPv6.*

*For example, `IPV6=yes` in `/etc/default/ufw`*

*Note: if you want to run an instance on a subdomain like 'forum',
then you should only add one record for that subdomain.*

```
# Example:
# Type:A, Name:forum.degenrocket.space, IPv4:20.21.03.01, TTL:3h
```

---

### About scripts

Please read the following notes before downloading and executing
the scripts for the initial server setup.

**Note 1.**

The first word in the name of the script specifies which user
should run the script (root, admin, user), e.g.:

```shell
# 03-root-setup-psql-create-db.sh
# 04-admin-setup-ssl.sh
# 05-user-setup-pm2.sh
```

If you created users with different names (e.g., Alice and Bob),
then 'root' and 'admin' scripts require sudo privileges.

**Note 2.**

If after executing some setup scripts, you've logged out
of the server and cannot log in as a root to continue,
then try to log in as a `user` with port `2222`, e.g.:

```shell
ssh -i ~/.ssh/user user@20.21.03.01 -P 2222
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
`set -euo pipefail` option at the top of the script.

Thus, you can try do delete that line and run the script again.

If that doesn't help, then try to rebuild the server from scratch.

If nothing helps, please create an issue to reach out for help
(see the **Contacts** section at the bottom of this guide). 

---

### Default directory and file structure

Here is the default directory and file structure that you'll have
after executing scripts for the automated initial server setup.

You can change these paths in the `scripts/.env` file.

```
root (manages initial server setup)
├── .ssh
│   └── authorized_keys (for the first connection only)
└── scripts (degenrocket-scripts.git)
    └── .env (this .env will be copied to user and admin)

home
├── user (npm, pm2, manages apps)
│   ├── .ssh
│   │   └── authorized_keys (for regular connections)
│   ├── apps
│   │   └── degenrocket
│   │       ├── frontend (degenrocket-web.git)
│   │       │   └── .env
│   │       └── backend (degenrocket-server.git)
│   │           └── .env
│   ├── backups
│   │   └── database (copied from admin during db backup)
│   └── scripts (degenrocket-scripts.git)
│       └── .env (copied from root during initial server setup)
│
└── admin (sudo, ssl, manages OS)
    ├── backups
    │   └── database (generated during database backups)
    └── scripts (degenrocket-scripts.git)
        └── .env (copied from root during initial server setup)
```

---

### Root setup

You should be logged in as `root`, so you can run setup scripts.

Install git.

```shell
apt-get install git
```

Download all scripts manually into `/root/scripts/` or using `git clone`.

```shell
# Create scripts folder
mkdir ~/scripts
```

```shell
# Download all scripts from github into scripts folder
git clone https://github.com/degenrocket/degenrocket-scripts.git ~/scripts/
```

Look through all downloaded scripts and compare them to the source
to make sure that you didn't download anything malicious.

```shell
# Example:
nano ~/scripts/initial-server-setup/01-root-setup-ssh-users-ufw-fail2ban.sh
```

#### Environment variables

You can change environment variables to minimize interactions
with automated scripts.

Copy `.env.example` file into `.env`.

```shell
cp ~/scripts/.env.example ~/scripts/.env
```

Set your domain name and IP address of your server.

```shell
nano ~/scripts/.env
```

Example:

```
DOMAIN_NAME=degenrocket.space
IP_ADDRESS=80.78.22.221
```

#### Execute scripts 01, 02, 03 from `root`.

```shell
bash ~/scripts/initial-server-setup/01-root-setup-ssh-users-ufw-fail2ban.sh
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

After running the script above your should be able to log into
your server as a user with a custom port. You can test that in
another terminal before running the next script.

Example:

```shell
ssh -i ~/.ssh/user user@20.21.03.01 -P 2222
```

*Note: username and port might be different if you've changed
them in the .env file.*

Next script.

```shell
bash ~/scripts/initial-server-setup/02-root-setup-apt-postgres-npm-nginx.sh
```

The script above will:
* Update the operating system
* Install and configure postgresql
* Install NVM
* Update npm
* Install required node version
* Install and configure Nginx

```shell
bash ~/scripts/initial-server-setup/03-root-setup-psql-create-db.sh
```

The script above will:
* Create a new postgres user without superuser privileges (default: dbuser)
* Grant that user a privilege to create new databases (used by some npm scripts)
* Set a password for a new user (default: dbuser)
* Create a new database (default: spasm_database) owned by a new user 
* Create required database tables

---

### Admin setup

Switch to an admin to execute the next script.

```shell
# Default password is 'admin'.
su - admin
```

There should already be a folder with latest scripts.

If not, copy-paste the script manually or use `git clone`, and then execute.

*This script will request an SSL certificate for https connection
and it requires a domain name, so skip this script if you're
simply testing the app via IP address on in the VM.*

Note: this script requires sudo (default password: admin)

```shell
sudo bash ~/scripts/initial-server-setup/04-admin-setup-ssl.sh
```

The script above will:
* Ask for your domain name (e.g., degenrocket.space)
* Install snapd
* Install Letsencrypt's certbot
* Request an SSL certificate (for HTTPS connection)
* Test auto-renewal of a certificate

*Note: if you want to a run an instance on a subdomain like
'forum.your_domain.com', then instead of running a script above,
you will have to manually execute the following commands to get
an SSL cerificate:*

```
sudo apt-get -y install snapd
sudo apt-get remove certbot -y
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot
sudo certbot --noninteractive --agree-tos --nginx --cert-name your_domain.com -d forum.your_domain.com --register-unsafely-without-email
sudo certbot renew --dry-run
```

Troubleshooting: sometimes you might get the following errors.

```
snapd.failure.service is a disabled or a static unit, not starting it
snapd.mounts-pre.target is a disabled or a static unit, not starting it
snapd.mounts.target is a disabled or a static unit, not starting it
snapd.snap-repair.service is a disabled or a static unit, not starting it
```

In this case, simply press any key or `ctrl-c`
and the process should continue.

If the process doesn't continue, then exit the process,
delete snapd, upgrade the system, and run the script again.

```shell
sudo apt purge snapd
sudo dpkg --configure -a
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade
sudo bash ~/scripts/initial-server-setup/04-admin-setup-ssl.sh
```

---

### User setup

Now switch to a user to execute final scripts.

```shell
# Default password is 'user'.
su - user
```

There should already be a folder with scripts.

If not, copy-paste the script manually or use `git clone`, and then execute:

```shell
bash ~/scripts/initial-server-setup/05-user-setup-pm2.sh
```

The script above will:
* Install pm2
* Add `pm2 resurrect` to cron jobs to start apps after each reboot

Next, we can finally instal the app.

```shell
bash ~/scripts/initial-server-setup/06-user-setup-git.sh
```

The following script will:
* Create folders to download the app
* Download the app with git
* Install dependencies

*Note: you can choose 'No' when Nuxt asks you to collect data.*

---

### Customize the app

Adjust `backend/.env` if you've changed default database user or password

```shell
nano ~/apps/degenrocket/backend/.env
```

Set app name, social media links and other options in `frontend/.env`

```shell
nano ~/apps/degenrocket/frontend/.env
```

Make sure `API_URL` is set properly in `frontend/.env`

Some examples:

```shell
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

```
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

```
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
 
Build and start the backend

```shell
npm run --prefix ~/apps/degenrocket/backend prod
```

Build and start the frontend

```shell
npm run --prefix ~/apps/degenrocket/frontend prod
```

Check running apps

```shell
pm2 list
```

Save running apps so they auto-start after each system reboot

```shell
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

```shell
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

```shell
# SSH into the server as a user
# Switch to an admin (default password: admin)
su - admin
```

##### 1. Change a defalt password for user.

```shell
sudo passwd user
```

##### 2. Change a defalt password for admin.

```shell
sudo passwd admin
```

##### 3. Change a defalt password for a database user.

Connect to the database from user or admin.

*Note: change `spasm_database`, `dbuser`, `5432` if you've used
custom values for `POSTGRES_DATABASE`, `POSTGRES_USER`, `POSTGRES_PORT`.*

```shell
psql -h localhost -d spasm_database -U dbuser -p 5432
```

Change a password of a database user and exit the database.

*Note: type your password instead of 'new_password'.*

```shell
ALTER USER dbuser WITH PASSWORD 'new_password';
exit
```

Change a default password in the backend `.env` file
to the same password as in the step above.

- Open the environment file.

```shell
vim ~/apps/degenrocket/backend/.env
```

- Change a value of the `POSTGRES_PASSWORD` variable, example:

```shell
POSTGRES_PASSWORD=new_password
```

*Note: use "" if your password has spaces, e.g.:*

```shell
POSTGRES_PASSWORD="my new password"
```

- Restart the backend pm2 instance

```shell
pm2 list
pm2 delete dr-prod-back
npm run --prefix ~/apps/degenrocket/backend prod
pm2 save
```

- Test the app in the browser.

---

### Home machine

**Test SSH**

It's recommended to SSH into the server from another terminal,
so you can troubleshoot your SSH configuration if you won't be able
to log in as a user with a new port.

You have to speficy a new SSH port (default: `2222`)
and a new user, because root login is disabled.

Example:

```shell
# Don't forget to change '20.21.03.01' to your server IP address
ssh -i ~/.ssh/user user@20.21.03.01 -P 2222
```

You can also add this to `~/.ssh/config` on your home machine:

```shell
# Don't forget to change '20.21.03.01' to your server IP address
Host my-server
  Hostname 20.21.03.01
  Port 2222
  User user
```

You should now be able to SSH into your server with this command:

```shell
ssh my-server
```

You can also open an SFTP connection to upload/download files:

```shell
sftp my-server
```

---

### Troubleshooting

#### Cors

The backend API should work even if your frontend and backend
have different IP addresses. However, if you still get cors
errors, consider enabling cors for all origins in the Nginx
config to see if the issue will be mitigated, e.g.:

```
location / {
    if ($request_method = 'GET') {
        add_header 'Access-Control-Allow-Origin' '*' always;
    }
}

location /api {
    if ($request_method = 'GET') {
        add_header 'Access-Control-Allow-Origin' '*' always;
    }
}
```


---

### Contacts

[Session](https://getsession.org): `degenrocket`

