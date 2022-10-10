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

echo "Deprecated...";
exit 200;

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

cd /usr/local/src;
rm -rf ./mongoui/;
${GIT_BIN} clone https://github.com/azat-co/mongoui.git

if [ -d "/usr/local/src/mongoui/" ] && [ -f "/usr/local/src/mongoui/index.js" ];
then
    rm -rf "/usr/local/mongoui/" 2>/dev/null;
    ${RSYNC_BIN} -avz "/usr/local/src/mongoui/" "/usr/local/mongoui/";
    cd /usr/local/mongoui/
    ${NPM_BIN} i;
fi;

echo "[OK] Completed...";

exit 0;
