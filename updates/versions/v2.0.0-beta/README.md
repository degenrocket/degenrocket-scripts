## Update to version `2.0.0-beta.x`

## New

### Spasm V2

The new version of DegenRocket is compatible with `spasm.js` v2
which has a new event structure, allowing groundbreaking 
features like multi-signing, marking the beginning of the future
of social media.

### Moderation

New backend environment variables:

```
IGNORE_WHITELIST_FOR_ACTION_REACT_IN_SPASM_MODULE
IGNORE_WHITELIST_FOR_ACTION_REPLY_IN_SPASM_MODULE
```

*Examples can be found in `./.env.example`.*

*Note: `IGNORE_WHITELIST_FOR_ACTION_POST_IN_SPASM_MODULE` should
be set to `true` if you want to receive new posts from other
instances of the Spasm Network signed with non-whitelisted
addresses. In other words, set it to `true` if you trust
moderators of other instances to properly filter out SPAM and
low-quality content on their instances.*

---

Note: if you don't use the default `npm run prod` script to
run the app, then make sure to build the app with
`npm run build` before starting it.

---

## Update with the script

#### Step 1. Change environment variables.

Change backend variables

```shell
nano ~/apps/degenrocket/backend/.env
```

Change frontend variables

```shell
nano ~/apps/degenrocket/frontend/.env
```

#### Step 2. Download and execute the update script.

You can download and execute the `user-update-to-latest-version.sh` script without sudo privileges.

If you followed the guide for initial server setup, then you can execute the update script with the following commands:

Download new scripts

```shell
cd ~/scripts && git reset --hard HEAD && git pull && cd ~/
```

Check the script to make sure that you didn't download anything malicious.

```shell
cat ~/scripts/updates/user-update-to-latest-version.sh | less
```

**Note: press `q` keyboard to quit `less`**

(Optional) Backup the database.

```shell
bash ~/scripts/database/user-database-backup.sh
```

Execute the update script

```shell
bash ~/scripts/updates/user-update-to-latest-version.sh
```

That's it. The update should be completed and you should be able to see the latest versions when running `pm2 list` or visiting the website.

You can know proceed with the database migration following the instruction at the end of this document.

## Manual update instruction

Download the new version

```shell
cd ~/apps/degenrocket/backend/ && git reset --hard HEAD && git pull
```

```shell
cd ~/apps/degenrocket/frontend/ && git reset --hard HEAD && git pull
```

(Optional) Add new variables to your backend environment.

```shell
nano ~/apps/degenrocket/backend/.env
```

(Optional) Add new variables to your frontend environment.

```shell
nano ~/apps/degenrocket/frontend/.env
```

IMPORTANT: change frontend and backend variables if needed before proceeding to the next step.

### Install packages

```shell
cd ~/apps/degenrocket/backend && npm install
cd ~/apps/degenrocket/frontend && npm install
```

Delete all previous pm2 app instances of DegenRocket and then spawn new ones. 

```shell
pm2 delete all
```

If you run other apps via pm2, then only delete DegenRocket instances, e.g.:

```shell
# See all instances
pm2 list
# Change 0 and 1 to the corresponding numbers of DegenRocket instances
pm2 delete 0
pm2 delete 1
```

Build and start the backend

```shell
npm run --prefix ~/apps/degenrocket/backend prod
```

Build and start the frontend

```shell
npm run --prefix ~/apps/degenrocket/frontend prod
```

### Check running apps

```shell
pm2 list
```

Save running apps so they auto-start after each system reboot

```shell
pm2 save
```

## Change environment variables (optional).

*Note: if you wish to change values of any environment variables once again, then don't forget to delete currently running pm2 instances and then execute `npm run prod` in frontend and backend folders. `npm run prod` will build the app and spawn new pm2 instances.*

Change backend variables

```shell
nano ~/apps/degenrocket/backend/.env
```

Change frontend variables

```shell
nano ~/apps/degenrocket/frontend/.env
```

Delete pm2 instances

```shell
pm2 delete all
```

Start the backend

```shell
npm run --prefix ~/apps/degenrocket/backend prod
```

Start the frontend

```shell
npm run --prefix ~/apps/degenrocket/frontend prod
```

Save instances

```shell
pm2 save
```

*Note: while running `pm2 restart all` is usually enough to apply all the environment changes, if you've changed ports (e.g., dev, staging, production ports, etc.), then restarting instances would not be enough. You'll need to delete running instances and then spawn new ones as explained above.*

You can know proceed with the database migration following the instruction at the end of this document.

---

## Database migration

The new version requires a new table `spasm_events` and a new testing database `your_database_name_test` (e.g., `spasm_database_test`). Thus, we have to create a new database and table and then migrate all web2 posts from the `posts` table and web3 events from the `actions` table into the new table `spasm_events`.

If your database user has superuser privileges, then you can simply execute a migration script from the backend (server) folder, e.g.:

```shell
cd ~/apps/degenrocket/backend/ && npm run migrate
```

If your database user doesn't have superuser privileges (recommended), then you have to either manually create a new database and table or grant your db user a privilege to create new databases.

### Option 1. Manually create

Log into your database as a superuser, e.g.:

```shell
su - admin
sudo su - postgres
psql
```

Create a new database for running tests.

Note: change `spasm_database` name to the name of your database.

```shell
\c spasm_database
CREATE DATABASE spasm_database_test;
```

Now you can execute SQL command from `./backend/database.sql` to
create missing tables for the main database.

Then you can connect to a test database with
`\c spasm_database_test` and execute the same SQL command
from `./backend/database.sql` to create tables for the test
database.

Lastly, exit database and run the migration script.

```shell
cd ~/apps/degenrocket/backend/ && npm run migrate
```

### Option 2. Grant privilege

Alternatively, you can grant your database user a privilege to create new databases.

Log into your database as a superuser, e.g.:

```shell
su - admin
sudo su - postgres
psql
```

Grant a new privilege with `ALTER USER your_username CREATEDB;`, e.g.:

```
ALTER USER dbuser CREATEDB;
```

And then exit the database and run the migration script.

```shell
cd ~/apps/degenrocket/backend/ && npm run migrate
```

