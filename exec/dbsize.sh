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

da_user="${1}";

# ======================================================================================================== #

DEBUG=${DEBUG:-0};

# ======================================================================================================== #

[ ! -f "/usr/local/directadmin/plugins/mongodb/exec/functions.inc.sh" ] && echo "[ERROR] Corrupted installation" && exit 1;
source /usr/local/directadmin/plugins/mongodb/exec/functions.inc.sh;

usage()
{
    echo "
=======================================================================
 A script to get size of all MongoDB databases owned by an user
=======================================================================

Usage:

$0 <da_user>

    <da_user>  - a directadmin user for which to calculate MongoDB size
";
    exit 0;
}

# ======================================================================================================== #

DBCONF="${DEFAULT_DBCONF}";

# ======================================================================================================== #

[ -n "${da_user}" ] || usage;
[ -f "${DBCONF}" ] || die "Could not find user config" 1;

dbhost=$(awk -F: '{print $1}' "${DBCONF}");
dbport=$(awk -F: '{print $2}' "${DBCONF}");
dbuser=$(awk -F: '{print $4}' "${DBCONF}");
dbpass=$(awk -F: '{print $5}' "${DBCONF}");

[ -n "${dbhost}" ] || die "Could not find dbhost in user conf ${DBCONF}" 3;
[ -n "${dbport}" ] || die "Could not find dbport in user conf ${DBCONF}" 4;
[ -n "${dbuser}" ] || die "Could not find dbuser in user conf ${DBCONF}" 5;
[ -n "${dbpass}" ] || die "Could not find dbpass in user conf ${DBCONF}" 6;

# ======================================================================================================== #

[ -d "/usr/local/directadmin/data/users/${da_user}/" ] || die "User ${da_user} does not exist in DirectAdmin" 30;

getDBSize()
{
    ${MONGO_BIN} --quiet <<EOF
    db = connect("${dbhost}:${dbport}/admin");
    db.auth("${dbuser}","${dbpass}");
    db.adminCommand( { listDatabases: 1, filter: { "name": /^${da_user}_/ } } );
EOF
}

dbsize=$(getDBSize | grep totalSize | awk '{print $NF}' | grep -o "[0-9]*");

if [ -n "${dbsize}" ]; then
    echo "${dbsize}";
else
    echo 0;
fi;

exit 0;
