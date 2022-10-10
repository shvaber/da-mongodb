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

$HTML_ADMIN_TEXT_OK = '';
$HTML_ADMIN_TEXT_ERROR = '';

if (!extension_loaded('mongodb'))
{
    $HTML_ADMIN_TEXT_ERROR = $da->get_lang('PLUGIN_ADMIN_MONGO_ERROR');
    $is_error = true;
}
else
{
    $HTML_ADMIN_TEXT_OK = $da->get_lang('PLUGIN_ADMIN_MONGO_OK');
    $is_error = false;

    $dbconn = $mongodb->testServer();
    if ($dbconn)
    {
        $HTML_ADMIN_TEXT_OK .= '<br>'.$da->get_lang('PLUGIN_ADMIN_MONGO_CONNECTED_OK');
        $is_error = false;
    }
    else
    {
        $HTML_ADMIN_TEXT_ERROR = $da->get_lang('PLUGIN_ADMIN_MONGO_CONNECTED_ERROR');
        $is_error = true;
    }
}

$MONGO_USAGE = 0;
$MONGO_USAGE_SIZE = 0;

if ($is_error !== true)
{
    if ($mongo_all_databases = $mongodb->getDatabasesList(false))
    {
        $MONGO_USAGE = $mongodb->getDatabasesCount();
        $MONGO_USAGE_SIZE = $mongodb->getDatabasesSize();
        $TABLE_LIST = format_table_list($mongo_all_databases, 'table_list');
    }
    else
    {
        $TABLE_LIST = '<tr><td colspan="4" class="text-center">'.$da->get_lang('PLUGIN_DATABASES_NOT_FOUND').'</td></tr>';
    }
}

$MAIN_CONTENT = [
    'PHP_MONGO_EXTENSION'    => ($is_error == false) ? $HTML_ADMIN_TEXT_OK : $HTML_ADMIN_TEXT_ERROR,
    'ALERT_CLASS'            => ($is_error == false) ? 'alert-success' : 'alert-danger',
    'PLUGIN_TH_DATABASE'     => $da->get_lang('PLUGIN_TH_DATABASE'),
    'PLUGIN_TH_DBOWNER'      => $da->get_lang('PLUGIN_TH_DBOWNER'),
    'PLUGIN_TH_DBSIZE'       => $da->get_lang('PLUGIN_TH_DBSIZE'),
    'PLUGIN_DB_COUNT'        => $da->get_lang('PLUGIN_DB_COUNT'),
    'PLUGIN_DB_SIZE'         => $da->get_lang('PLUGIN_DB_SIZE'),
    'PLUGIN_FOOTER_TITLE'    => sprintf($da->get_lang('PLUGIN_FOOTER_TITLE'), PLUGIN_VERSION),
    'PLUGIN_TABLE_LIST'      => $TABLE_LIST,
    'PLUGIN_DB_USAGE'        => $MONGO_USAGE,
    'PLUGIN_DB_USAGE_SIZE'   => $MONGO_USAGE_SIZE,
];

$TPL_DATA = [
    'PLUGIN_HOME_TITLE'            => $da->get_lang('PLUGIN_HOME_TITLE'),
    'PLUGIN_HOME_DESCRIPTION'      => $da->get_lang('PLUGIN_HOME_DESCRIPTION'),
    'PLUGIN_FOOTER_TITLE'          => sprintf($da->get_lang('PLUGIN_FOOTER_TITLE'), PLUGIN_VERSION),
    'PLUGIN_MONGOADMIN_CLASS'      => ' sr-only',
    'PLUGIN_MONGOADMIN_LINK'       => MONGOADMIN_LINK,
    'PLUGIN_MONGOADMIN_CONNECT'    => $da->get_lang('PLUGIN_CONNECT_MONGOADMIN'),
    'PLUGIN_SELECTED_DATABASE'     => '',
    'MAIN_CONTENT'                 => _get_tpl(PLUGIN_TPL_DIR . '/admin.html', $MAIN_CONTENT),
    'SERVER_TIME'                  => date(TIME_DATE_FORMAT),
    'UUID'                         => gen_uuid(),
];

if ($is_error)
{
    $TPL_DATA['DISABLED']             = ' disabled="disabled"';
    $TPL_DATA['MESSAGE_HTML']         = '';
    $TPL_DATA['ERROR_HTML']           = $error_message .' '. ($error_details ? $error_details : '');
}
else
{
    $TPL_DATA['MESSAGE_HTML']         = $message_ok;
    $TPL_DATA['ERROR_HTML']           = '';
}

do_output(generate_page($TPL_DATA));

// terminate here
exit;
