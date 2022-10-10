<?php
######################################################################################
#
#   MongoDB integration for DirectAdmin $ 0.2
#   ==============================================================================
#          Last modified: Mon Feb 10 12:44:48 +07 2020
#   ==============================================================================
#         Written by Alex Grebenschikov, Poralix, www.poralix.com
#         Copyright 2019 by Alex Grebenschikov, Poralix, www.poralix.com
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

$database = (isset($_GET['database']) && $_GET['database']) ? $_GET['database'] : false;
$databases = array();

if ($mongodb_user_databases = $mongodb->getDatabasesList($USER))
{
    foreach ($mongodb_user_databases as $row)
    {
        if (($USER === $row['owner']) || (strpos($row['owner'], $USER."_") === 0))
        {
            $databases[] = $row['name'];
        }
    }
    if (in_array($database, $databases))
    {
        $tmp_dir = sys_get_temp_dir() or '/tmp';
        $file = false;
        if (is_executable(PLUGIN_DUMPDB_BIN) && is_file($sso_config_file))
        {
            $file = tempnam($tmp_dir, $database.'.temp');
            $cmd = PLUGIN_DUMPDB_BIN. ' '.escapeshellarg($database).' '. escapeshellarg($sso_config_file) .' '. escapeshellarg($file);
            @exec($cmd, $output, $rtval);
        }
        if (is_file($file))
        {
            print "Content-Disposition: attachment; filename=".basename($database).".tar.gz\n";
            print "Expires: 0\n";
            print "Cache-Control: must-revalidate\n";
            print "Pragma: public\n";
            print "Content-Length: " . filesize($file)."\n";
            print "Content-type: application/tar+gzip\n\n";
            readfile($file);
            unlink($file);
            exit;
        }
        else
        {
            $is_error = true;
        }
    }
    else
    {
        $is_error = true;
        $error_message = $da->get_lang('ERROR_MESSAGE_FAILED_DOWNLOAD');
        $error_details = $da->get_lang('ERROR_DETAILS_FAILED_OWNER');
    }
}
else
{
    $is_error = true;
    $error_message = $da->get_lang('ERROR_MESSAGE_FAILED_DOWNLOAD');
    $error_details = $da->get_lang('ERROR_DETAILS_FAILED_LIST_DATABASES');
}

if ($is_error)
{
    print "Cache-Control: no-cache, must-revalidate\n";
    print "Content-type: text/html\n\n";
    //var_dump($cmd, $result, $output, $tmp_dir, $file);
    if (!$error_message) $error_message = $da->get_lang('ERROR_MESSAGE_FAILED_DOWNLOAD');
    if (!$error_details) $error_details = $da->get_lang('ERROR_DETAILS_FAILED_DOWNLOAD');
}
