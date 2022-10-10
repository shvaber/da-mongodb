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

de()
{
    if [ "1" == "${DEBUG}" ];
    then
        if [ -n "${1}" ]; then
            echo "[DEBUG] ${1}";
            return;
        else
            while read data; do echo "[DEBUG] ${data}"; done;
        fi;
    fi;
}

die()
{
    exit_msg=${1};
    exit_code=${2:-250};
    echo "[ERROR] ${exit_msg}";
    [ -n "${LOG_FILE}" ] && log "[ERROR] ${exit_msg}";
    exit "${exit_code}";
}

MONGO_BIN="/usr/local/bin/mongo";
[ ! -x "${MONGO_BIN}" ] && MONGO_BIN="/usr/bin/mongo";
[ ! -x "${MONGO_BIN}" ] && MONGO_BIN="/bin/mongo";
[ ! -x "${MONGO_BIN}" ] && die "[ERROR] MongoDB is not installed! You should first install MongoDB." 20;

RESTORE_BIN="/usr/local/bin/mongorestore";
[ ! -x "${RESTORE_BIN}" ] && RESTORE_BIN="/usr/bin/mongorestore";
[ ! -x "${RESTORE_BIN}" ] && RESTORE_BIN="/bin/mongorestore";
[ ! -x "${RESTORE_BIN}" ] && die "[ERROR] Could not find ${RESTORE_BIN}" 20;

DUMP_BIN="/usr/local/bin/mongodump";
[ ! -x "${DUMP_BIN}" ] && DUMP_BIN="/usr/bin/mongodump";
[ ! -x "${DUMP_BIN}" ] && DUMP_BIN="/bin/mongodump";
[ ! -x "${DUMP_BIN}" ] && die "[ERROR] Could not find ${DUMP_BIN}" 20;

DEFAULT_DBCONF="/usr/local/directadmin/plugins/mongodb/mongopass.conf";
DBDUMPSINGLE_SCRIPT="/usr/local/directadmin/plugins/mongodb/exec/dbdumpsingle.sh";
DBRESTORE_SCRIPT="/usr/local/directadmin/plugins/mongodb/exec/dbrestore.sh";
