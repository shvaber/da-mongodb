#!/bin/bash
######################################################################################
#
#   MongoDB integration for DirectAdmin $ 0.2
#   ==============================================================================
#          Last modified: Mon Feb 10 12:44:48 +07 2020
#   ==============================================================================
#         Written by Alex Grebenschikov, Poralix, www.poralix.com
#         Copyright 2019-2022 by Alex Grebenschikov, Poralix, www.poralix.com
#   ==============================================================================
#         Distributed under Apache License Version 2.0, January 2004
#                                          http://www.apache.org/licenses/
#
######################################################################################

#PSQL_ADMIN="diradmin";
#PSQL_CONF="/usr/local/directadmin/plugins/mongodb/pgpass.conf";
#PSQL_USER_CONF="/usr/local/directadmin/.pgpass";

MONGO_BIN="/usr/local/bin/mongo";
[ ! -x "${MONGO_BIN}" ] && MONGO_BIN="/usr/bin/mongo";
[ ! -x "${MONGO_BIN}" ] && echo "[ERROR] MongoDB is not installed! You should first install MongoDB." && exit 1;

GIT_BIN="/usr/local/bin/git";
[ ! -x "${GIT_BIN}" ] && GIT_BIN="/usr/bin/git";
[ ! -x "${GIT_BIN}" ] && echo "[ERROR] Git is not installed! You should first install git." && exit 2;

RSYNC_BIN="/usr/local/bin/rsync";
[ ! -x "${RSYNC_BIN}" ] && RSYNC_BIN="/usr/bin/rsync";
[ ! -x "${RSYNC_BIN}" ] && echo "[ERROR] Rsync is not installed! You should first install rsync." && exit 3;

PHPVER=$(php -v | grep ^PHP | awk '{print $2}' | grep ^5.[0-9]*.[0-9]*);
if [ -z "${PHPVER}" ]; then
    echo "[ERROR] Only PHP 5.x with mongo extension is supported";
    exit 10;
fi;

cd /usr/local/src;
rm -rf ./phpMoAdmin-MongoDB-Admin-Tool-for-PHP/;
${GIT_BIN} clone https://github.com/MongoDB-Rox/phpMoAdmin-MongoDB-Admin-Tool-for-PHP.git
cd ./phpMoAdmin-MongoDB-Admin-Tool-for-PHP/ && VER=$(grep ^Version change.log | head -1 | awk '{print $2}');
echo "DirectoryIndex index.php moadmin.php" >> .htaccess;

if [ -n "${VER}" ];
then
    rm -rf /var/www/html/phpMoAdmin* 2>/dev/null;
    ${RSYNC_BIN} -avz ./ "/var/www/html/phpMoAdmin-${VER}/";
    ln -s "/var/www/html/phpMoAdmin-${VER}" "/var/www/html/phpMoAdmin";
    chown -R webapps:webapps "/var/www/html/phpMoAdmin-${VER}";
    chown -h webapps:webapps "/var/www/html/phpMoAdmin";
fi;

echo "[OK] Rewriting web-server configs...";
cd /usr/local/directadmin/custombuild;
mkdir -p custom;
c=$(grep -m1 -c "^phpmoadmin=" custom/webapps.list 2>/dev/null);
[ "1" == "${c}" ] && perl -pi -e "s/^phpmoadmin=.*\n//" custom/webapps.list;
echo "phpmoadmin=phpMoAdmin" >> custom/webapps.list;
./build rewrite_confs

echo "[OK] Completed...";

exit 0;
