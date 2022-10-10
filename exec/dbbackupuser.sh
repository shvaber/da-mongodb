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
dbdump_dir="${2}";

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
 A script to dump all Mongo databases of an user to a dir (BSON format)
=======================================================================

Usage:

$0 <da_user> <output_dir>

    <da_user>         - directadmin user to dump
    <output_dir>      - directory to save dump files to
";
    exit 0;
}

# ======================================================================================================== #

DBCONF="${DEFAULT_DBCONF}";
USER_SESSION_CONF_FILE="/usr/local/directadmin/plugins/mongodb/data/sso/user.${da_user}.mongo.conf";

# ======================================================================================================== #

[ -n "${da_user}" ] || usage;
[ -n "${dbdump_dir}" ] || usage;
[ -d "${dbdump_dir}" ] || die "Target directory does not exist" 2;
[ -f "${DBCONF}" ] || die "Could not find user conf" 1;

dbhost=$(awk -F: '{print $1}' "${DBCONF}");
dbport=$(awk -F: '{print $2}' "${DBCONF}");
dbuser=$(awk -F: '{print $4}' "${DBCONF}");
dbpass=$(awk -F: '{print $5}' "${DBCONF}");
dbname="";

[ -n "${dbhost}" ] || die "Could not find dbhost in user conf ${DBCONF}" 3;
[ -n "${dbport}" ] || die "Could not find dbport in user conf ${DBCONF}" 4;
[ -n "${dbuser}" ] || die "Could not find dbuser in user conf ${DBCONF}" 5;
[ -n "${dbpass}" ] || die "Could not find dbpass in user conf ${DBCONF}" 6;

# ======================================================================================================== #

# GET LIST OF ALL USER'S DATABASES
for dbname in $({
${MONGO_BIN} --quiet <<EOF
    db = connect("${dbhost}:${dbport}/admin");
    db.auth("${dbuser}","${dbpass}");
    db.getMongo().getDBNames().forEach(function(db){print(db)});
EOF
} | grep "^${da_user}_");
do
    "${DBDUMPSINGLE_SCRIPT}" "${dbname}" "${USER_SESSION_CONF_FILE}" "${dbdump_dir}/${dbname}.tar.gz";
done;

exit 0;
