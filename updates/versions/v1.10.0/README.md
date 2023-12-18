## Update to version `1.10.x`

## New

### Add support short URLs

Short URLs are enabled by default with a default length of 20 symbols.

An example of a full URL:

```
https://degenrocket.space/news/0xbd934a01dc3bd9bb183bda807d35e61accf7396c527b8a3d029c20c00b294cf029997be953772da32483b077eea856e6bafcae7a2aff95ae572af25dd3e204a71b
```

An example of a short URL (20 symbols):

```
https://degenrocket.space/news/0xbd934a01dc3bd9bb18
```

Environment variables to enable/disable short URLs.

```
# ~/apps/degenrocket/frontend/.env
ENABLE_SHORT_URLS_FOR_WEB3_ACTIONS=true
SHORT_URLS_LENGTH_OF_WEB3_IDS="20"
```

```
# ~/apps/degenrocket/backend/.env
ENABLE_SHORT_URLS_FOR_WEB3_ACTIONS=true
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

Note: if you wish to change new environment variables, then don't forget to rebuild the frontend and restart pm2 instances after that.

#### Change environment variables

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

Note: while running `pm2 restart all` is usually enough to apply all the environment changes, if you've changed ports (e.g., dev, staging, production ports, etc.), then restarting instances would not be enough. You'll need to delete running instances and then spawn new ones. 

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

(Optional) Add new variables to your backend environment.

```
nano ~/apps/degenrocket/backend/.env
```

(Optional) Add new variables to your frontend environment.

```
nano ~/apps/degenrocket/frontend/.env
```

IMPORTANT: change frontend and backend variables if needed before proceeding to the next step.

### Install packages and build the app

```
cd ~/apps/degenrocket/backend && npm install
cd ~/apps/degenrocket/frontend && npm install && npm run build
```

Delete all previous pm2 app instances of DegenRocket and then spawn new ones. 

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
