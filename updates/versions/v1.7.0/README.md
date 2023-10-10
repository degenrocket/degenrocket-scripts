## Update to version `1.7.x`

## New

### Change all environment variables to one-line values

**IMPORTANT CHANGE!**

Make sure that all variables in `frontend/.env` and `backend/.env` files contain only one-line values.

### Hide one-line URLs

URLs that take up the whole line can now be hidden if they will be embedded via iframe tags. To enable this feature, set the following variable to `true` in `frontend/.env`.

```
IFRAME_HIDE_ONE_LINE_URL=true
```

### Disable new web3 actions

New web3 actions can be disabled in `frontend/.env` and `backend/.env` with the following variables.

```
ENABLE_NEW_WEB3_ACTIONS_ALL=false
ENABLE_NEW_WEB3_ACTIONS_POST=false
ENABLE_NEW_WEB3_ACTIONS_REPLY=false
ENABLE_NEW_WEB3_ACTIONS_REACT=false
ENABLE_NEW_WEB3_ACTIONS_MODERATE=false
```

---

## Update with the script

You can download and execute the `user-update-to-latest-version.sh` script without sudo privileges.

If you followed the guide for initial server setup, then you can execute the update script with the following commands:

Download new scripts

```
cd ~/scripts && git reset --hard HEAD && git pull
```

Check the script to make sure that you didn't download anything malicious.

```
cat ~/scripts/updates/user-update-to-latest-version.sh | less
```

Execute the update script

```
bash ~/scripts/updates/user-update-to-latest-version.sh
```

That's it. The update should be completed and you should be able to see the latest versions when running `pm2 list` or visiting the website.

Note: if you wish to change new environment variables (e.g., to disable all new web3 posts), then don't forget to rebuild the frontend and restart pm2 instances after that.

Change environment variables

```
nano ~/apps/degenrocket/backend/.env
```

```
nano ~/apps/degenrocket/frontend/.env
```

Rebuild the frontend

```
cd ~/apps/degenrocket/frontend && npm run build
```

Restart pm2 instances

```
pm2 restart all
```

Note: while running `pm2 restart all` is usually enough to apply all the enviroment changes, if you've changed ports (e.g., dev, staging, production ports, etc.), then restarting instances would not be enough. You'll need to delete running instances and then spawn new ones. 

```
# Delete instances
pm2 delete all
# Start the backend
cd ~/apps/degenrocket/backend && npm run prod && cd ~/
# Start the frontend
cd ~/apps/degenrocket/frontend && npm run prod && cd ~/
# Save instances
pm2 save
```

## Manual update instruction

Download the new version

```
cd ~/apps/degenrocket/backend/ && git reset --hard HEAD && git pull
```

```
cd ~/apps/degenrocket/frontend/ && git reset --hard HEAD && git pull
```

(Optional) Add new variables to your backend enviroment.

```
nano ~/apps/degenrocket/backend/.env
```

```
# Enable various web3 actions with true/false
ENABLE_NEW_WEB3_ACTIONS_ALL=true
ENABLE_NEW_WEB3_ACTIONS_POST=true
ENABLE_NEW_WEB3_ACTIONS_REPLY=true
ENABLE_NEW_WEB3_ACTIONS_REACT=true
ENABLE_NEW_WEB3_ACTIONS_MODERATE=true
```

(Optional) Add new variables to your frontend enviroment.

```
nano ~/apps/degenrocket/frontend/.env
```

```
# Enable various web3 actions with true/false
ENABLE_NEW_WEB3_ACTIONS_ALL=true
ENABLE_NEW_WEB3_ACTIONS_POST=true
ENABLE_NEW_WEB3_ACTIONS_REPLY=true
ENABLE_NEW_WEB3_ACTIONS_REACT=true
ENABLE_NEW_WEB3_ACTIONS_MODERATE=true
```

```
# Hide standalone URL if it takes up the whole line with true/false.
IFRAME_HIDE_ONE_LINE_URL=false
```

IMPORTANT: change frontend and backend variables if needed before proceeding to the next step.

### Install packages and build the app

```
cd ~/apps/degenrocket/backend && npm install
cd ~/apps/degenrocket/frontend && npm install && npm run build
```

Since we've changed pm2-related variables, we have to delete all previous pm2 app instances of DegenRocket and then spawn new ones. 

```
pm2 delete all
```

If you run other apps via pm2, then only delete DegenRocket instances, e.g.:

```
# See all instances
pm2 list
# Change 0 and 1 to the corresponding numbers of DegenRocket instances
pm2 delete 0
pm2 delete 1
```

Start the backend

```
cd ~/apps/degenrocket/backend && npm run prod && cd ~/
```

Start the frontend

```
cd ~/apps/degenrocket/frontend && npm run prod && cd ~/
```

# Check running apps

```
pm2 list
```

Save running apps so they auto-start after each system reboot

```
pm2 save
```
