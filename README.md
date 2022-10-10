# MongoDB module

1. requirements:

- PHP extension `mongodb`


# phpMoAdmin - MongoDB GUI

1. requirements:

- PHP extension `mongodb`

# Scripts:

- **exec/dbbackupuser.sh** - a script to backup MongoDB DBs and users, used by DirectAdmin
- **exec/dbdump.sh** - a script to dump a single MongoDB DB
- **exec/dbrestore.sh** - a script to restore a single MongoDB DB
- **exec/dbsize.sh** - a script to get size of all DBs created by user in DirectAdmin
- **exec/dbusage.sh** - a script to get count of all DBs created by user in DirectAdmin

# It is REQUIRE 
- to re-save User Package or the user's account and set up how much databases it can handle. Including the user "admin"
- needs to install mongodb module for PHP to run mongoadmin and plugin using standart DA way. Like this one: https://www.interserver.net/tips/kb/custom-php-modules-directadmin/

# License

Apache License
==============

Version 2.0, January 2004
http://www.apache.org/licenses/
