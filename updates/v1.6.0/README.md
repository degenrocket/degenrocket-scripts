## Update to version `1.6.x`

### Iframe

Links to the external content like videos can now be embedded via `<iframe>` tags for whitelisted users and whitelisted domains. For security reasions, iframe tags are disabled in the posts and comments by default.

If you want to enable iframe tags for whitelisted users, here is an example configuration:

```
ENABLE_EMBED_IFRAME_TAGS_FOR_SELECTED_USERS=true
ENABLE_EMBED_IFRAME_TAGS_IN_POSTS=true
ENABLE_EMBED_IFRAME_TAGS_IN_COMMENTS=false
IFRAME_VIDEO_WIDTH="640"
IFRAME_VIDEO_HEIGHT="520"
IFRAME_ADDITIONAL_PARAMS="allowfullscreen"
```

Note: even if you enable iframe tags, it's recommended to disable them in the comments, because in some browsers videos from certain CDNs will autoplay even though the autoplay is disabled.

Also don't forget to whitelist users and domains, see examples in `.env` file:

```
SIGNERS_ALLOWED_TO_EMBED_IFRAME_TAGS="0x56bc5fcf4922d8dc29adc8567b6221ff26ff7ae8,0x4e94cc43fb152ac12d3f45d7dd420f794a9e6205"
IFRAME_TAGS_ALLOWED_DOMAINS="https://iframe.mediadelivery.net/embed/,https://example.com/embed/,https://www.example.com/embed/"
```

WARNING: you should use iframe tags with great caution, because allowing external content to be embedded via iframe HTML tags is a potential security vulnerability on any platform (not only DegenRocket). If you wish to enable iframe HTML tags, then you should only allow to trusted signers with good security practices. There are multiple security checks implemented, but keep in mind that if a signer leaks a private key, it can be potentially used to exploit the app by serving malicious code via the iframe tags.

### Ports

You can now specify custom ports for development, staging, and production for frontend and backend in corresponding `.env` files, as well as `exec mode` and `instances` for pm2 ecosystem config file.

Example backend

```
PORT=5001
BACKEND_PORT=5001
BACKEND_STAGE_PORT=5002
BACKEND_PROD_PORT=5000
BACKEND_PM2_PROD_INSTANCES='max'
BACKEND_PM2_STAGE_INSTANCES='1'
BACKEND_PM2_PROD_EXEC_MODE='cluster'
BACKEND_PM2_STAGE_EXEC_MODE='cluster'
```

Example frontend

```
PORT=3001
FRONTEND_DEV_PORT=3001
FRONTEND_STAGE_PORT=3002
FRONTEND_PROD_PORT=3000
FRONTEND_PM2_PROD_INSTANCES='max'
FRONTEND_PM2_STAGE_INSTANCES='1'
FRONTEND_PM2_PROD_EXEC_MODE='cluster'
FRONTEND_PM2_STAGE_EXEC_MODE='cluster'
```

---

## Update with the script

You can download and execute the `user-update-to-v1.6.1.sh` script without sudo privileges.

If you followed the guide for initial server setup, then you can execute the update script with the following commands:

```
# Download new scripts
cd ~/scripts && git reset --hard HEAD && git pull
# Execute the update script
bash ~/scripts/updates/v1.6.0/user-update-to-v1.6.1.sh
```

If you wish to change new environment variables (e.g., to enable iframe tags), then don't forget to rebuild the frontend and restart pm2 instances after that.

Change environment variables

```
nano ~/apps/degenrocket/backend/.env
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

Note: while running `pm2 restart all` is usually enough to apply all the enviroment changes, if you've changed ports (e.g., dev, staging, production ports, etc.), then restarting instances would not be enough. You'll need to delete running insctances and then spawn new ones. 

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
cd ~/apps/degenrocket/frontend/ && git reset --hard HEAD && git pull
```

(Optional) Add new variables to your backend enviroment.

```
nano ~/apps/degenrocket/backend/.env
```

```
# Default port
PORT=5000
BACKEND_PORT=5000
# Staging port
BACKEND_STAGE_PORT=5000
# Production port
BACKEND_PROD_PORT=5000
# How many instances pm2 should spawn (depends of CPU cores)
# Value: '1', '2', '3',..., 'max' (default: 'max'), e.g.:
# BACKEND_PM2_PROD_INSTANCES='max'
BACKEND_PM2_PROD_INSTANCES='max'
BACKEND_PM2_STAGE_INSTANCES='1'
# Choose mode: cluster/fork
BACKEND_PM2_PROD_EXEC_MODE='cluster'
BACKEND_PM2_STAGE_EXEC_MODE='cluster'
```

(Optional) Add new variables to your backend enviroment.

```
nano ~/apps/degenrocket/frontend/.env
```

Port and other pm2-related variables

```
# Default port
PORT=3000
# Development port
FRONTEND_DEV_PORT=3000
# Staging port
FRONTEND_STAGE_PORT=3000
# Production port
FRONTEND_PROD_PORT=3000
# How many instances pm2 should spawn (depends of CPU cores)
# Value: '1', '2', '3',..., 'max' (default: 'max'), e.g.:
# FRONTEND_PM2_PROD_INSTANCES='max'
FRONTEND_PM2_PROD_INSTANCES='max'
FRONTEND_PM2_STAGE_INSTANCES='1'
# Choose mode: cluster/fork
FRONTEND_PM2_PROD_EXEC_MODE='cluster'
FRONTEND_PM2_STAGE_EXEC_MODE='cluster'
```

Iframe-related variables

```
# Allow video embedding via iframe tags
# WARNING: potential security vulnerability,
# so use with caution. Only allow to trusted
# signers with good security practices.
# If a signer leaks a private key, it can be
# potentially used to exploit the app by serving
# malicious code via the iframe tags.
# Default: false
ENABLE_EMBED_IFRAME_TAGS_FOR_SELECTED_USERS=false
ENABLE_EMBED_IFRAME_TAGS_IN_POSTS=false
ENABLE_EMBED_IFRAME_TAGS_IN_COMMENTS=false
# Whitelist signers for iframe tags
# Separate eligible signers with comma, e.g.:
# SIGNERS_ALLOWED_TO_EMBED_IFRAME_TAGS="0x56bc5fcf4922d8dc29adc8567b6221ff26ff7ae8,0x4e94cc43fb152ac12d3f45d7dd420f794a9e6205"
SIGNERS_ALLOWED_TO_EMBED_IFRAME_TAGS=""
# Additional security check.
# Provide domains that can embed videos with iframe tags.
# Separate whitelisted domains with comma.
# For security reasons specify full domain names with '/' at the end.
# If you set "https://video.com" without '/' at the end, then
# a malicious whitelisted signer will be able to add iframe tags
# from the following domain "https://video.communityhacker.io".
# To allow all domains, type whitelisted protocols "https,ipfs".
# Example:
# IFRAME_TAGS_ALLOWED_DOMAINS="https://iframe.mediadelivery.net/embed/,https://youtube.com/embed/,https://www.youtube.com/embed/"
IFRAME_TAGS_ALLOWED_DOMAINS=""
IFRAME_VIDEO_WIDTH="640"
IFRAME_VIDEO_HEIGHT="520"
# Separate additional params with empty space.
# Add 'allowfullscreen' to allow full screen, e.g.:
# IFRAME_ADDITIONAL_PARAMS="allowfullscreen"
IFRAME_ADDITIONAL_PARAMS="allowfullscreen"
```

IMPORTANT: change frontend and backend variables if needed before proceeding to the next step.

### Install packages and build the app

```
cd ~/apps/degenrocket/backend && npm install
cd ~/apps/degenrocket/fronted && npm install && npm run build
```

Since we've added port and pm2-related enviroment variables, we have to delete all previous pm2 app instances of DegenRocket and then spawn new ones. 

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

```
# Start the backend
cd ~/apps/degenrocket/backend && npm run prod && cd ~/
# Start the frontend
cd ~/apps/degenrocket/frontend && npm run prod && cd ~/
```

```
# Check running apps
pm2 list

# Save running apps so they auto-start after each system reboot
pm2 save
```

