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

USER_DATABASE="${1}";
USER_SESSION_CONF_FILE="${2}";
DUMP_FILE="${3}";

# ======================================================================================================== #

DEBUG=${DEBUG:-0};
GZIP=${GZIP:-1};

# ======================================================================================================== #

[ ! -f "/usr/local/directadmin/plugins/mongodb/exec/functions.inc.sh" ] && echo "[ERROR] Corrupted installation" && exit 1;
source /usr/local/directadmin/plugins/mongodb/exec/functions.inc.sh;

usage()
{
    echo "
=======================================================================
 A script to restore a single Mongo database from a file (BSON format)
=======================================================================

Usage:

$0 <db_name> <user_conf_file> <dump_gz_file>

    <db_name>         - a database to restore
    <user_conf_file>  - a file to user's credentials
    <dump_gz_file>    - a file to restore from
";
    exit 0;
}

do_restore()
{
    de "Processing ${1}";

    if [ "0" == "${GZIP}" ];
    then
        ${RESTORE_BIN} --host=${dbhost} --port=${dbport} --username=${dbuser} --password="${dbpass}" --db="${dbname}" --drop "${2}";
    else
        dbdump_dir=$(dirname "${2}");
        dbdump_file=$(basename "${2}");
        restore_dir="${dbdump_dir}/${dbdump_file/.tar.gz/}";
        test -d "${restore_dir}" && rm -rf "${restore_dir}";
        tar -zxf "${2}" --directory=${dbdump_dir};
        if [ -d "${restore_dir}" ];
        then
            gunzip -f "${restore_dir}"/*.gz;
            ${RESTORE_BIN} --host=${dbhost} --port=${dbport} --username=${dbuser} --password="${dbpass}" --db="${dbname}" --drop "${restore_dir}";
            rm -rf "${restore_dir}";
        fi;
    fi;
}

# ======================================================================================================== #

DBCONF="${USER_SESSION_CONF_FILE}";

# ======================================================================================================== #

[ -n "${USER_DATABASE}" ] || usage;
[ -n "${DBCONF}" ] || usage;
[ -n "${DUMP_FILE}" ] || usage;
[ -f "${DBCONF}" ] || die "Could not find user conf" 1;
[ -f "${DUMP_FILE}" ] || die "Could not find user's dump file" 2;

GZIP=$(echo "${DUMP_FILE}" | egrep -c '\.gz$');

dbhost=$(awk -F: '{print $1}' "${DBCONF}");
dbport=$(awk -F: '{print $2}' "${DBCONF}");
dbuser=$(awk -F: '{print $4}' "${DBCONF}");
dbpass=$(awk -F: '{print $5}' "${DBCONF}");
dbname="${USER_DATABASE}";

[ -n "${dbhost}" ] || die "Could not find dbhost in user conf ${DBCONF}" 3;
[ -n "${dbport}" ] || die "Could not find dbport in user conf ${DBCONF}" 4;
[ -n "${dbuser}" ] || die "Could not find dbuser in user conf ${DBCONF}" 5;
[ -n "${dbpass}" ] || die "Could not find dbpass in user conf ${DBCONF}" 6;

# ======================================================================================================== #

do_restore "${dbname}" "${DUMP_FILE}";

exit 0;
