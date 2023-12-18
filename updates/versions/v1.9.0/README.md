## Update to version `1.9.x`

## New

### Add QR codes and external explorer links

Each Ethereum and Nostr address has icons to copy the address, show a QR code, or view the address on an external explorer.

Environment variables to change default explorers.

```
# ~/apps/degenrocket/frontend/.env
DEFAULT_EXPLORER_ETHEREUM_ADDRESS='https://etherscan.io/address/'
DEFAULT_EXPLORER_NOSTR_ADDRESS='https://satellite.earth/@'
```

*Note: the URL should contain a full path, e.g. `https://satellite.earth/@` instead of `https://satellite.earth/`, or `https://etherscan.io/address/` instead of `https://etherscan.io/`.*

### Hide new post button from menu

It's possible to hide a **publish** button from the menu.

```
# ~/apps/degenrocket/frontend/.env
SHOW_NEW_POST_BUTTON_IN_MENU=true
```

*Note: that doesn't disable the creation of new posts via `yourdomain.com/newpost` page.*

### Default license is CC0-1.0

The default license of all signed messages/events has been changed from **MIT** to **CC0-1.0** since it better suits text messages. You can read the full discussion about licenses [here](https://github.com/nostr-protocol/nips/pull/857).

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
