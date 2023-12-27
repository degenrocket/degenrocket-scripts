## Update to version `1.12.x`

## New

Converted the backend to TypeScript.

The backend entry point has changed to `./dist/api/index.js`.

If you don't use default `npm run prod` script to run the app, then
make sure to build the app with `npm run build` before starting it.

---

## Update with the script

You can download and execute the `user-update-to-latest-version.sh` script without sudo privileges.

If you followed the guide for initial server setup, then you can execute the update script with the following commands:

Download new scripts

```shell
cd ~/scripts && git reset --hard HEAD && git pull
```

Check the script to make sure that you didn't download anything malicious.

```shell
cat ~/scripts/updates/user-update-to-latest-version.sh | less
```

Execute the update script

```shell
bash ~/scripts/updates/user-update-to-latest-version.sh
```

That's it. The update should be completed and you should be able to see the latest versions when running `pm2 list` or visiting the website.

*Note: if you wish to change values of any environment variables, then don't forget to delete currently running pm2 instances and then execute `npm run prod` in frontend and backend folders. `npm run prod` will build the app and spawn new pm2 instances.*

#### Change environment variables

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

# Check running apps

```shell
pm2 list
```

Save running apps so they auto-start after each system reboot

```shell
pm2 save
```
