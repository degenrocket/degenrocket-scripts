### TIPS

#### How to delete a post?

Connect to the database

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

