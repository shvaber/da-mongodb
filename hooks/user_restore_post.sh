#!/bin/bash
######################################################################################
#
#   MongoDB integration for DirectAdmin $ 0.2
#   ==============================================================================
#          Last modified: Mon Feb 10 12:44:48 +07 2020
#   ==============================================================================
#         Written by Alex Grebenschikov, Poralix, www.poralix.com
#         Copyright 2022 by Alex Grebenschikov, Poralix, www.poralix.com
#   ==============================================================================
#
#   LICENSE:
#   SOURCE CODE AND SCRIPTING POLICY
#
#   1.Purchase of the source code or scripting, coding means that
#   you have the license rights but you do not own the code.
#   Poralix grants to you one (1) personal, nontransferable,
#   royalty-free license to make and use copies of the source code
#   and install such source code on any number of servers for his
#   internal use. You may not redistribute the source code, or any
#   component thereof, whether modified or not to any third party.
#
#   2.Source code usage is for your personal use or for your company.
#   It is not to be shared with other parties.
#
#   3.You are not allowed to resell, transfer, rent, lease, or
#   sublicense the source code and associated rights.
#
#   4.Under no circumstances may any portion of the source code or
#   any modified version or derivative work of the source code be
#   distributed, disclosed or otherwise made available to any third
#   party.
#
#   5.Customer is allowed only to modify it for his own usage only.
#
#   6.If you'd want to resell the Software, we have special terms and
#   price is increased accordingly.
#
#   7.The Software or any part of its code cannot be used as a basis
#   for a competing control panel, server management system, or
#   similar product.
#
#   8.If you sell your business including the Software source codes
#   both the seller and buyer MUST contact Poralix for code transfer.
#
#   This page is an obligatory part of the Terms of Service for
#   Server Management Clients and all extended policies posted
#   here should be agreed and accepted prior to signing up with
#   our service.
#
#   Source Code and Scripting Policy:
#   https://www.poralix.com/user-area/source-code-and-scripting-policy/
#
######################################################################################

# DirectAdmin variables:
# - username=joe
# - reseller=resellername
# - filename=/path/to/the/user.tar.gz

USERNAME="${username}";
RESELLER="${reseller}";
FILE="${filename}";
SCRIPT="/usr/local/directadmin/plugins/mongodb/exec/dbimport.sh";
LOG_DIR="/usr/local/directadmin/plugins/mongodb/logs";

do_restore()
{
    if [ -n "${USERNAME}" ] && [ -n "${FILE}" ] && [ -f "${FILE}" ];
    then
    {
        "${SCRIPT}" "${USERNAME}" "${FILE}" > ${LOG_DIR}/restore.user.${USERNAME}.$(date +%Y%m%d.%s).log 2>&1;
    }
    else
    {
        # Error
        echo "No user selected....";
    }
    fi;
}

do_restore;

exit 0;
