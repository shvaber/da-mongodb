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
user_backup="${2}";

# ======================================================================================================== #

DEBUG=${DEBUG:-0};

# ======================================================================================================== #

[ ! -f "/usr/local/directadmin/plugins/mongodb/exec/functions.inc.sh" ] && echo "[ERROR] Corrupted installation" && exit 1;
source /usr/local/directadmin/plugins/mongodb/exec/functions.inc.sh;

usage()
{
    echo "
=======================================================================
 A script to import all MongoDB databases owned by an user
=======================================================================

Usage:

$0 <da_user> <backup_file>

    <da_user>       - a directadmin user to import in MongoDB
    <backup_file>   - a full path to a tar.gz file with DirectAdmin backup
";
    exit 0;
}

da_import_data()
{
    tar -zxf "${1}" -C "${2}" "backup/mongodb/" --strip-components=1;
    IMPORT_DIR="${2}/mongodb";
    if [ -d "${IMPORT_DIR}" ];
    then
        for FILE in $(find "${IMPORT_DIR}" -type f -name \*.tar.gz);
        do
            db_name=$(basename "${FILE}");
            db_name=${db_name/.tar.gz/};
            "${DBRESTORE_SCRIPT}" "${db_name}" "${USER_SESSION_CONF_FILE}" "${FILE}" 2>&1;
        done;
    fi;
}

# ======================================================================================================== #

DBCONF="${DEFAULT_DBCONF}";
USER_SESSION_CONF_FILE="/usr/local/directadmin/plugins/mongodb/data/sso/user.${da_user}.mongo.conf";

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
[ -f "${user_backup}" ] || die "File ${user_backup} does not exist on the server. Terminating..." 40;

export TEMP_DIR=$(mktemp --directory /home/tmp/.${da_user}.XXXXXXXX);

da_import_data "${user_backup}" "${TEMP_DIR}";
test -d "${TEMP_DIR}" && rm -rf "${TEMP_DIR}";

exit 0;
