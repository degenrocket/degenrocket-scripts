### Database backup

#### Database backup as a user

You can execute `user-database-backup.sh` as `user` to create a backup of a database into the `user` home directory so you can download it using `sftp`.

Requires: database user password.

Example:

```
bash ~/scripts/database/user-database-backup.sh
```

By default a backup is created at:

```
/home/user/apps/backups/database/news_database_CURRENT_DATE.sql
```

*Note: you can change default paths in `~/scripts/.env`.*

#### Database backup as an admin

You can execute `admin-database-backup.sh` as `admin` to create a backup of a database into the `admin` home directory and copy the backup to the `user` home directory so you can download it using `sftp`.

Requires: database user password, admin password.

Example:

```
bash ~/scripts/database/admin-database-backup.sh
```

By default backups are created at:

```
/home/user/backups/database/news_database_CURRENT_DATE.sql
/home/admin/backups/database/news_database_CURRENT_DATE.sql
```

*Note: you can change default paths in `~/scripts/.env`.*

##### Why execute the database backup script as `admin`?

Ideally, you want to have regular automatic backups to the cloud or at least download them locally. However, if you can't configure an advanced backup process, then backing the database as `admin` will give you an extra copy in the `admin` home folder in case if you mess up `user` folders or if an attacker will be able to get an access to `user` and delete your backups.

#### Restore database

If you want to restore the database from the backup,
execute the following command from a user or an admin:

```
psql -h localhost -U dbuser news_database < news_database_20230101.sql
```

*Note: change `news_database_20230101` to the name of your database backup file, and don't forget to change default db name `news_database`, db username `dbuser`, and db port `5432` if you've used custom values.*

### TIPS

#### How to delete a post?

Connect to the database

*Note: don't forget to change default db name `news_database`, db username `dbuser`, and db port `5432` if you've used custom values.*

```
psql -h localhost -d news_database -U dbuser -p 5432
```

Delete the post via signature

```
DELETE FROM actions WHERE SIGNATURE='';
```

Add the signature between ' '.

The signature of the post can be copied from its URL.

For example, to delete the following post:

```
https://degenrocket.space/news/0xce6ca8c19ad124bb16f7dbf6ebbc059789a750818965b660147bf079f942bf5d26935a0420ffa4d0b477e4f5fa4c00844aae65ae06999a9e74fed71f464bcd811b
```

You have to execute the following command:

```
DELETE FROM actions WHERE SIGNATURE='0xce6ca8c19ad124bb16f7dbf6ebbc059789a750818965b660147bf079f942bf5d26935a0420ffa4d0b477e4f5fa4c00844aae65ae06999a9e74fed71f464bcd811b';
```

To delete all posts from a particular address, you have to use a similar command, but change `SIGNATURE` to `SIGNER`:

```
DELETE FROM actions WHERE SIGNER='';
```

For example, to delete all posts from address `0xd268cca7c12b38834568ddf4d48b333090612313` execute:

```
DELETE FROM actions WHERE SIGNER='0xd268cca7c12b38834568ddf4d48b333090612313';
```
