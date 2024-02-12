### Update to the latest version with a script

You can execute `user-update-to-latest-version.sh` as `user` to update the app to the latest version.

The script will also create a backup git branch called `previous-version` with your current version.

Example:

```
bash ~/scripts/updates/user-update-to-latest-version.sh
```

### Revert to a previous version with a script

You can execute `user-revert-to-previous-version.sh` as `user` to revert the app to the previous version if the `previous-version` git branch exists (e.g., if a backup was created by the `user-update-to-latest-version.sh` script).

Example:

```
bash ~/scripts/updates/user-revert-to-previous-version.sh
```
