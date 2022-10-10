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

USERNAME="${username}";
RESELLER="${reseller}";
FILE="${file}";

SCRIPT="/usr/local/directadmin/plugins/mongodb/exec/dbbackupuser.sh";
LOG_DIR="/usr/local/directadmin/plugins/mongodb/logs";

do_backup()
{
    WHOAMI="$(whoami)";

    if [ -n "${USERNAME}" ] && [ -n "${RESELLER}" ] && [ -n "${FILE}" ];
    then
    {
        USER_HOMEDIR="$(grep "^${USERNAME}:" /etc/passwd | cut -d: -f6)";
        RESELLER_HOMEDIR="$(grep "^${RESELLER}:" /etc/passwd | cut -d: -f6)";

        # USER LEVEL BACKUPS: =/home/${USERNAME}/backups
        # RESELLER LEVEL BACKUPS: =/home/${RESELLER}/user_backups
        # ADMIN LEVEL BACKUPS: =/home/???/admin_backups/???
        BACKUP_DIR="$(dirname ${FILE})";

        if [ "${BACKUP_DIR}" == "${USER_HOMEDIR}/backups" ];
        then
            # USER_LEVEL BACKUPS
            BACKUP_DIR="$(dirname ${FILE})/backup";
        elif [ "${BACKUP_DIR}" == "${RESELLER_HOMEDIR}/user_backups" ];
        then
            # RESELLER LEVEL BACKUPS
            BACKUP_DIR="$(dirname ${FILE})/${USERNAME}/backup";
        else
            # ADMIN LEVEL BACKUPS
            BACKUP_DIR="$(dirname ${FILE})/${USERNAME}/backup";
        fi;

        MONGODB_BACKUP_DIR="${BACKUP_DIR}/mongodb/";
        echo "DirectAdmin is backuping user ${USERNAME} into temporary folder ${BACKUP_DIR}";
        if [ -d "${BACKUP_DIR}" ];
        then
            echo "MongoDB will be backupped to ${MONGODB_BACKUP_DIR} and then compressed";
            mkdir -v "${MONGODB_BACKUP_DIR}";
            chmod -v 700 "${MONGODB_BACKUP_DIR}";
            "${SCRIPT}" "${USERNAME}" "${MONGODB_BACKUP_DIR}";
            chown -v -R "${USERNAME}:${USERNAME}" "${MONGODB_BACKUP_DIR}";
            echo "MongoDB backup completed:";
            ls -la "${MONGODB_BACKUP_DIR}";
        fi;
    }
    else
    {
        # Error
        echo "No user selected....";
    }
    fi;
}

do_backup > ${LOG_DIR}/backup.user.${USERNAME}.$(date +%Y%m%d.%s).log 2>&1;

exit 0;
