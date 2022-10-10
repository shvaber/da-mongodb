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

echo "Exiting...";
exit;

MONGO_BIN="/usr/local/bin/mongo";
[ ! -x "${MONGO_BIN}" ] && MONGO_BIN="/usr/bin/mongo";
[ ! -x "${MONGO_BIN}" ] && echo "[ERROR] MongoDB is not installed! You should first install MongoDB." && exit 1;

GIT_BIN="/usr/local/bin/git";
[ ! -x "${GIT_BIN}" ] && GIT_BIN="/usr/bin/git";
[ ! -x "${GIT_BIN}" ] && echo "[ERROR] Git is not installed! You should first install git." && exit 2;

RSYNC_BIN="/usr/local/bin/rsync";
[ ! -x "${RSYNC_BIN}" ] && RSYNC_BIN="/usr/bin/rsync";
[ ! -x "${RSYNC_BIN}" ] && echo "[ERROR] Rsync is not installed! You should first install rsync." && exit 3;

NODEJS_BIN="/usr/local/bin/node";
[ ! -x "${NODEJS_BIN}" ] && NODEJS_BIN="/usr/bin/node";
[ ! -x "${NODEJS_BIN}" ] && echo "[ERROR] Node.JS is not installed! You should first install Node.JS." && exit 4;

NPM_BIN="/usr/local/bin/npm";
[ ! -x "${NPM_BIN}" ] && NPM_BIN="/usr/bin/npm";
[ ! -x "${NPM_BIN}" ] && echo "[ERROR] NPM is not installed! You should first install NPM." && exit 5;

GIT_URL="https://github.com/mongodb-js/compass.git";
PROG_NAME="compass";

cd /usr/local/src;
rm -rf "./${PROG_NAME}/";
${GIT_BIN} clone "${GIT_URL}";

if [ -d "/usr/local/src/${PROG_NAME}/" ] && [ -f "/usr/local/src/${PROG_NAME}/package.json" ];
then
    rm -rf "/usr/local/${PROG_NAME}/" 2>/dev/null;
    ${RSYNC_BIN} -avz "/usr/local/src/${PROG_NAME}/" "/usr/local/${PROG_NAME}/";
    cd /usr/local/${PROG_NAME}/;
    ${NPM_BIN} i;
    ${NPM_BIN} audit fix;
fi;

echo "[OK] Completed...";

exit 0;
