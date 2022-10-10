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

MONGO_CONF="/usr/local/directadmin/plugins/mongodb/mongopass.conf";
MONGO_USER_CONF="/usr/local/directadmin/.mongopass";

######################################################################################

if [ -f "${MONGO_CONF}" ]; then
    ROW=$(head -1 ${MONGO_CONF});
    if [ -n "${ROW}" ]; then
        MONGO_HOST=$(echo "${ROW}" | cut -d: -f1);
        MONGO_PORT=$(echo "${ROW}" | cut -d: -f2);
        MONGO_DB=$(echo "${ROW}" | cut -d: -f3);
        MONGO_ADMIN=$(echo "${ROW}" | cut -d: -f4);
        MONGO_PASS=$(echo "${ROW}" | cut -d: -f5);
    fi;
fi;

MONGO_HOST="${MONGO_HOST:-localhost}";
MONGO_PORT="${MONGO_PORT:-27017}";
MONGO_DB="${MONGO_DB:-*}";
MONGO_ADMIN="${MONGO_ADMIN:-diradmin}";
MONGO_ADMIN_DB="${MONGO_ADMIN_DB:-admin}";
MONGO_PASS="${MONGO_PASS}";

######################################################################################

NEED_REMOVE=0;

# FIRST CHECK
c=$(${MONGO_BIN} --quiet --eval 'printjson(db.getUser("'${MONGO_ADMIN}'"))' ${MONGO_ADMIN_DB} 2>/dev/null | grep -v -w "null" | wc -l); #'
if [ "0" == "${c}" ]; then
    echo "[WARNING] User ${MONGO_ADMIN} does not exist in MongoDB!";
else
    echo "[OK] Going to remove ${MONGO_ADMIN} from MongoDB!";
    NEED_REMOVE=1;
fi;

echo "[OK] Disabling a password based authentication in MongoDB";

MONGO_CONF_PASSWORDLESS="/usr/local/directadmin/plugins/mongodb/scripts/setup/sources/mongod.conf.passwordless";

for MONGO_CONF_FILE in $(ls -1 /etc/mongod.conf 2>/dev/null);
do
    if [ -f "${MONGO_CONF_FILE}" ];
    then
        cp -p "${MONGO_CONF_FILE}" "${MONGO_CONF_FILE}.bak$(date +%s)";
        cat "${MONGO_CONF_PASSWORDLESS}" > "${MONGO_CONF_FILE}";
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

[ "${NEED_REMOVE}" == "1" ] && ${MONGO_BIN} --quiet --eval 'printjson(db.dropUser("'${MONGO_ADMIN}'"))' ${MONGO_ADMIN_DB} 2>/dev/null;

[ -f "${MONGO_CONF}" ] && rm -f "${MONGO_CONF}";
[ -f "${MONGO_USER_CONF}" ] && rm -f "${MONGO_USER_CONF}";

exit 0;
