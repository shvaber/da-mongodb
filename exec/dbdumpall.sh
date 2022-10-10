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

dbdump_dir="${1}";

# ======================================================================================================== #

DEBUG=${DEBUG:-0};
GZIP=${GZIP:-1};
SINGLE_FILE=${SINGLE_FILE:-1};

# ======================================================================================================== #

[ ! -f "/usr/local/directadmin/plugins/mongodb/exec/functions.inc.sh" ] && echo "[ERROR] Corrupted installation" && exit 1;
source /usr/local/directadmin/plugins/mongodb/exec/functions.inc.sh;

usage()
{
    echo "
=======================================================================
 A script to dump all Mongo databases to a directory (BSON format)
=======================================================================

Usage:

$0 <output_dir>

    <output_dir>     - a directory to save dump
";
    exit 0;
}

do_dump()
{
    de "Saving to ${1}";
    [ -d "${dbdump_dir}" ] || die "Directory ${dbdump_dir} does not exist...." 2;

    if [ "1" == "${GZIP}" ];
    then
        ${DUMP_BIN} --host=${dbhost} --port=${dbport} --username=${dbuser} --password="${dbpass}" --out="${dbdump_dir}" --gzip;
    else
        ${DUMP_BIN} --host=${dbhost} --port=${dbport} --username=${dbuser} --password="${dbpass}" --out="${dbdump_dir}";
    fi;
}

# ======================================================================================================== #

DBCONF="${DEFAULT_DBCONF}";

# ======================================================================================================== #

[ -n "${dbdump_dir}" ] || usage;
[ -f "${DBCONF}" ] || die "Could not find user conf" 1;

dbhost=$(awk -F: '{print $1}' "${DBCONF}");
dbport=$(awk -F: '{print $2}' "${DBCONF}");
dbuser=$(awk -F: '{print $4}' "${DBCONF}");
dbpass=$(awk -F: '{print $5}' "${DBCONF}");

[ -n "${dbhost}" ] || die "Could not find dbhost in user conf ${DBCONF}" 3;
[ -n "${dbport}" ] || die "Could not find dbport in user conf ${DBCONF}" 4;
[ -n "${dbuser}" ] || die "Could not find dbuser in user conf ${DBCONF}" 5;
[ -n "${dbpass}" ] || die "Could not find dbpass in user conf ${DBCONF}" 6;

# ======================================================================================================== #

do_dump "${dbdump_dir}";

exit 0;
