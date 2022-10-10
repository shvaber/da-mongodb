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
OUTPUT_FILE="${3}";

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
 A script to dump a single Mongo database to a file (BSON format)
=======================================================================

Usage:

$0 <db_name> <user_conf_file> <output_file>

    <db_name>         - a database to dump
    <user_conf_file>  - a file to user's credentials
    <output_file>     - a file to save dump
";
    exit 0;
}

do_dump()
{
    de "Processing ${1}";
    [ -d "${dbdump_dir}" ] || die "Directory ${dbdump_dir} does not exist...." 2;

    [ -d "${dbdump_dir}/${dbname}" ] && rm -rf "${dbdump_dir}/${dbname}";

    if [ "0" == "${GZIP}" ];
    then
        ${DUMP_BIN} --host=${dbhost} --port=${dbport} --username=${dbuser} --password="${dbpass}" --db="${dbname}" --out="${dbdump_dir}" --quiet;
    else
        ${DUMP_BIN} --host=${dbhost} --port=${dbport} --username=${dbuser} --password="${dbpass}" --db="${dbname}" --out="${dbdump_dir}" --gzip --quiet;
    fi;

    if [ -d "${dbdump_dir}/${dbname}" ]; then
        cd "${dbdump_dir}";
        tar -zcf "${OUTPUT_FILE}" "${dbname}";
        rm -rf "${dbdump_dir}/${dbname}";
        cd - >/dev/null;
    fi;

    [ -f "${OUTPUT_FILE}" ] && echo "${OUTPUT_FILE}";
}

# ======================================================================================================== #

DBCONF="${USER_SESSION_CONF_FILE}";

# ======================================================================================================== #

[ -n "${USER_DATABASE}" ] || usage;
[ -n "${DBCONF}" ] || usage;
[ -n "${OUTPUT_FILE}" ] || usage;
[ -f "${DBCONF}" ] || die "Could not find user conf" 1;

dbhost=$(awk -F: '{print $1}' "${DBCONF}");
dbport=$(awk -F: '{print $2}' "${DBCONF}");
dbuser=$(awk -F: '{print $4}' "${DBCONF}");
dbpass=$(awk -F: '{print $5}' "${DBCONF}");
dbname="${USER_DATABASE}";
dbdump_dir=$(dirname "${OUTPUT_FILE}");
dbdump_file=$(basename "${OUTPUT_FILE}");

[ -n "${dbhost}" ] || die "Could not find dbhost in user conf ${DBCONF}" 3;
[ -n "${dbport}" ] || die "Could not find dbport in user conf ${DBCONF}" 4;
[ -n "${dbuser}" ] || die "Could not find dbuser in user conf ${DBCONF}" 5;
[ -n "${dbpass}" ] || die "Could not find dbpass in user conf ${DBCONF}" 6;

# ======================================================================================================== #

do_dump "${dbname}" "${dbdump_dir}";

exit 0;
