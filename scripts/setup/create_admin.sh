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

for ARG in "$@"
do
    case "${ARG}" in
        --strict)
            STRICT=1;
        ;;
        --debug)
            DEBUG=1;
        ;;
    esac;
done;

######################################################################################

genpasswd()
{
    local l=${1:-20};
    tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs;
}

write_conf()
{
    echo "${MONGO_HOST}:${MONGO_PORT}:${MONGO_DB}:${MONGO_ADMIN}:${MONGO_PASS}" > "${1}";
    chown diradmin:diradmin "${1}";
    chmod 600 "${1}";
}

######################################################################################

[ ! -f "/usr/local/directadmin/plugins/mongodb/exec/functions.inc.sh" ] && echo "[ERROR] Corrupted installation" && exit 1;
source /usr/local/directadmin/plugins/mongodb/exec/functions.inc.sh;

######################################################################################

MONGO_HOST="localhost";
MONGO_PORT="27017";
MONGO_DB="*";
MONGO_ADMIN="diradmin";
MONGO_ADMIN_DB="admin";
MONGO_PASS=$(genpasswd);
MONGO_CONF="/usr/local/directadmin/plugins/mongodb/mongopass.conf";
MONGO_USER_CONF="/usr/local/directadmin/.mongopass";

PHP_TEST_SRC_FILE="/usr/local/directadmin/plugins/mongodb/scripts/setup/test_php.php.src";
PHP_TEST_TRG_FILE="/usr/local/directadmin/plugins/mongodb/exec/test_php.php";

######################################################################################

UPDATE_PASSWORD=0;

# FIRST CHECK
c=$(${MONGO_BIN} --quiet --eval 'printjson(db.getUser("'${MONGO_ADMIN}'"))' ${MONGO_ADMIN_DB} 2>/dev/null | grep -v -w "null" | wc -l); #'
if [ "0" == "${c}" ];
then
    echo "[OK] Adding user ${MONGO_ADMIN} into MongoDB!";
    echo "[OK] Setting password for ${MONGO_ADMIN} to '${MONGO_PASS}'!";
    ${MONGO_BIN} --quiet --eval 'db.createUser({user: "'${MONGO_ADMIN}'", pwd: "'${MONGO_PASS}'", roles: [ { role: "userAdminAnyDatabase", db: "admin" }, "readWriteAnyDatabase", {role: "root", db: "admin"} ]});' ${MONGO_ADMIN_DB};

    # SECOND CHECK AFTER CREATION
    c=$(${MONGO_BIN} --quiet --eval 'printjson(db.getUser("'${MONGO_ADMIN}'"))' ${MONGO_ADMIN_DB} 2>/dev/null | grep -v -w "null" | wc -l); #'
    if [ "0" == "${c}" ];
    then
        echo "[ERROR] Failed to create user ${MONGO_ADMIN}!";
        exit 1;
    else
        echo "[OK] User ${MONGO_ADMIN} created fine!";
        UPDATE_PASSWORD=1;
    fi;
else
    echo "[WARNING] User ${MONGO_ADMIN} already exists in MongoDB!";
    echo "[WARNING] Changing password for ${MONGO_ADMIN} to '${MONGO_PASS}'!";
    ${MONGO_BIN} --quiet --eval 'db.changeUserPassword("'${MONGO_ADMIN}'", "'${MONGO_PASS}'")'; #'
    [ "0" == "$?" ] && UPDATE_PASSWORD=1;
fi;

if [ "1" == "${UPDATE_PASSWORD}" ];
then
    echo "[OK] Writing configs for MongoDB superuser access.";
    write_conf "${MONGO_CONF}";
    write_conf "${MONGO_USER_CONF}";

    if [ -f "${PHP_TEST_SRC_FILE}" ]; 
    then
        cat "${PHP_TEST_SRC_FILE}" > "${PHP_TEST_TRG_FILE}";
        perl -pi -e "s#\|DBNAME\|#${MONGO_ADMIN_DB}#" "${PHP_TEST_TRG_FILE}";
        perl -pi -e "s#\|USERNAME\|#${MONGO_ADMIN}#" "${PHP_TEST_TRG_FILE}";
        perl -pi -e "s#\|PASSWORD\|#${MONGO_PASS}#" "${PHP_TEST_TRG_FILE}";
    fi;
fi;

echo "[OK] Setting a password based authentication in MongoDB";

MONGO_CONF_PASSWORDLESS="/usr/local/directadmin/plugins/mongodb/scripts/setup/sources/mongod.conf.passwordless";

if [ "1" == "${STRICT}" ]; then
    MONGO_CONF_PASSWORD="/usr/local/directadmin/plugins/mongodb/scripts/setup/sources/mongod.conf.password";
else
    MONGO_CONF_PASSWORD="/usr/local/directadmin/plugins/mongodb/scripts/setup/sources/mongod.conf.password";
fi;

for MONGO_CONF_FILE in $(ls -1 /etc/mongod.conf 2>/dev/null);
do
    if [ -f "${MONGO_CONF_FILE}" ];
    then
        cp -p "${MONGO_CONF_FILE}" "${MONGO_CONF_FILE}.bak$(date +%s)";
        cat "${MONGO_CONF_PASSWORD}" > "${MONGO_CONF_FILE}";
        echo "[OK] Updating MongoDB settings in ${MONGO_CONF_FILE}";
    fi;
done;

echo "[OK] Restarting MongoDB server";

if [ -x "/usr/bin/systemctl" ];
then
    /usr/bin/systemctl restart mongod.service;
else
    /usr/sbin/service mongod restart;
fi;

# TEST CONNECTION
chmod 600 ${PHP_TEST_SRC_FILE};
chmod 700 ${PHP_TEST_TRG_FILE};
php -f${PHP_TEST_TRG_FILE};

exit 0;
