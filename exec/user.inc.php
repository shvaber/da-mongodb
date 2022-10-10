<?php
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

ignore_user_abort(true);
set_time_limit(0);
error_reporting(0);

if (!defined('IN_DA_PLUGIN') || (IN_DA_PLUGIN !==true)){die("You're not allowed to view this page!");}
if (!defined('PLUGIN_ACTION')) {define('PLUGIN_ACTION','home');}
if ( defined('IN_JSON_OUTPUT') && (IN_JSON_OUTPUT == true))
{
    print "HTTP/1.1 200 OK\n";
    print "Cache-Control: no-cache, must-revalidate\n";
    print "Content-type: application/json\n\n";
    define('FILE_TYPE', 'json');
    $append_go_back_link_on_error = false;
}
else if ( defined('IN_RAW_OUTPUT') && (IN_RAW_OUTPUT == true))
{
    print "HTTP/1.1 200 OK\n";
    print "Cache-Control: no-cache, must-revalidate\n";
    define('FILE_TYPE', 'raw');
    $append_go_back_link_on_error = true;
    // ALL THE OTHER HEADERS WILL BE SENT LATER
}
else if ( defined('IN_DOWNLOAD_OUTPUT') && (IN_DOWNLOAD_OUTPUT == true))
{
    print "HTTP/1.1 200 OK\n";
    define('FILE_TYPE', 'raw');
    $append_go_back_link_on_error = false;
    // ALL THE OTHER HEADERS WILL BE SENT LATER
}
else
{
    define('IN_HTML_OUTPUT', true);
    define('IN_JSON_OUTPUT', false);
    define('IN_RAW_OUTPUT', false);
    define('FILE_TYPE', 'html');
    $append_go_back_link_on_error = true;
}


require_once('functions.inc.php');
require_once(PLUGIN_EXEC_DIR . '/class.inc.php');
require_once(PLUGIN_EXEC_DIR . '/class.mongodb.inc.php');
if  (is_file(PLUGIN_EXEC_DIR . '/settings.local.inc.php')) {require_once(PLUGIN_EXEC_DIR . '/settings.local.inc.php');}
require_once(PLUGIN_EXEC_DIR . '/settings.inc.php');

parse_input();
_get_credentials();

$is_error = false;
$message_ok = false;
$error_message = false;
$error_details = false;

$USER = isset($_SERVER['USER']) ? $_SERVER['USER'] : '';
$HOME = isset($_SERVER['HOME']) ? $_SERVER['HOME'] : '';
$SESSION_DOMAIN = isset($_SERVER['SESSION_SELECTED_DOMAIN']) ? $_SERVER['SESSION_SELECTED_DOMAIN'] : '';

$da = new da();
$mongodb = new mongodb([
    'user'     => MONGO_USER,
    'password' => MONGO_PASSWORD,
    'host'     => MONGO_HOST,
    'port'     => MONGO_PORT,
    'dbname'   => 'admin',
]);

$sso_config_file = PLUGIN_SSO_DIR . '/user.'. $USER .'.mongo.conf';

// PROCESS ACTION
$action_file = sprintf("%s/%s/%s.php", PLUGIN_ACTION_DIR, FILE_TYPE, basename(PLUGIN_ACTION));

$MONGO_USER_LIMIT = $da->get_user_data('mongodb');
$MONGO_USER_USAGE = $mongodb->getDatabasesCount($USER);
$MONGO_USER_USAGE_SIZE = $mongodb->getDatabasesSize($USER);

if (is_null($MONGO_USER_LIMIT) || ($MONGO_USER_LIMIT == 0) || !$MONGO_USER_LIMIT)
{
    $is_error = true;
    $error_message = $da->get_lang('ERROR_MESSAGE_MONGO_NOT_ALLOWED');
    $error_details = $da->get_lang('ERROR_DETAILS_MONGO_NOT_ALLOWED');
    $action_file = sprintf("%s/%s/%s.php", PLUGIN_ACTION_DIR, FILE_TYPE, 'error');
}
else
{
    if (is_file($action_file))
    {
        require_once($action_file);
    }
    else
    {
        $is_error = true;
        $error_message = $da->get_lang('ERROR_MESSAGE_UNKNOWN_ACTION');
        $error_details = $da->get_lang('ERROR_DETAILS_UKNOWN_DETAILS');
    }
}

// HTML pages should not go here
// This case is expected to be for JSON
// to avoid duplicating lines of code
if ($is_error == true)
{
    if ( defined('IN_RAW_OUTPUT') && (IN_RAW_OUTPUT == true))
    {
        print "HTTP/1.1 200 OK\n";
        print "Cache-Control: no-cache, must-revalidate\n";
        print "Content-Type: text/html\n\n";
    }

    $append_go_back_link = $append_go_back_link_on_error ?  $da->get_lang('PLUGIN_GO_BACK_LINK') : '';
    do_output(generate_page([
        'MESSAGE_HTML'            => false,
        'ERROR_HTML'              => $error_message .': '. $error_details."<br><br>". $append_go_back_link,
        'SERVER_TIME'             => date(TIME_DATE_FORMAT),
        'OUTPUT_DATA'             => ['action' => PLUGIN_ACTION],
        'UUID'                    => gen_uuid(),
        'MAIN_CONTENT'            => '',
        'PLUGIN_FOOTER_TITLE'     => '',
        'PLUGIN_HOME_TITLE'            => $da->get_lang('PLUGIN_HOME_TITLE'),
        'PLUGIN_HOME_DESCRIPTION'      => $da->get_lang('PLUGIN_HOME_DESCRIPTION'),
        'PLUGIN_MONGOADMIN_CLASS'      => ' sr-only',
        'PLUGIN_MONGOADMIN_LINK'       => MONGOADMIN_LINK,
        'PLUGIN_SELECTED_DATABASE'     => (isset($database) && $database) ? $database : ((isset($dbname) && $dbname) ? $dbname : false),
        'PLUGIN_MONGOADMIN_CONNECT'    => $da->get_lang('PLUGIN_CONNECT_MONGOADMIN'),
        ])
    );
}
else
{
    do_output(generate_page([
        'MESSAGE_HTML'         => $message_ok,
        'ERROR_HTML'           => false,
        'SERVER_TIME'          => date(TIME_DATE_FORMAT),
        'OUTPUT_DATA'          => ['action' => PLUGIN_ACTION],
        'UUID'                 => gen_uuid(),
        'MAIN_CONTENT'         => '',
        'PLUGIN_FOOTER_TITLE'  => '',
        'PLUGIN_HOME_TITLE'            => $da->get_lang('PLUGIN_HOME_TITLE'),
        'PLUGIN_HOME_DESCRIPTION'      => $da->get_lang('PLUGIN_HOME_DESCRIPTION'),
        'PLUGIN_MONGOADMIN_CLASS'      => '',
        'PLUGIN_MONGOADMIN_LINK'       => MONGOADMIN_LINK,
        'PLUGIN_SELECTED_DATABASE'     => (isset($database) && $database) ? $database : ((isset($dbname) && $dbname) ? $dbname : false),
        'PLUGIN_MONGOADMIN_CONNECT'    => $da->get_lang('PLUGIN_CONNECT_MONGOADMIN'),
        ])
    );
}

exit;
