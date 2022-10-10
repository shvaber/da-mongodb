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

// DOES AN USER'S PACKAGE HAVE ENOUGH CAPACITY?
if (($MONGO_USER_USAGE === $MONGO_USER_LIMIT) || ($MONGO_USER_USAGE > $MONGO_USER_LIMIT))
{
    $is_error = true;
    $error_message = $da->get_lang('ERROR_MESSAGE_MONGO_LIMIT_HIT');
    $error_details = $da->get_lang('ERROR_DETAILS_MONGO_LIMIT_HIT');
}


$MAIN_CONTENT = [
    'PHP_MONGO_EXTENSION'      => ($is_error == false) ? $HTML_ADMIN_TEXT_OK : $HTML_ADMIN_TEXT_ERROR,
    'ALERT_CLASS'              => ($is_error == false) ? 'alert-success' : 'alert-danger',
    'PLUGIN_DB_CREATE'         => $da->get_lang('PLUGIN_DB_CREATE'),
    'PLUGIN_DB_CREATE_NEW'     => $da->get_lang('PLUGIN_DB_CREATE_NEW'),
    'PLUGIN_DB_RESTORE'        => $da->get_lang('PLUGIN_DB_RESTORE'),
    'PLUGIN_GO_BACK'           => $da->get_lang('PLUGIN_GO_BACK'),
    'PLUGIN_DB_NAME'           => $da->get_lang('PLUGIN_DB_NAME'),
    'PLUGIN_DB_USER'           => $da->get_lang('PLUGIN_DB_USER'),
    'PLUGIN_DB_PASSWORD'       => $da->get_lang('PLUGIN_DB_PASSWORD'),
    'PLUGIN_DB_SAME_USERNAME'  => $da->get_lang('PLUGIN_DB_SAME_USERNAME'),
    'DISABLED'                 => $is_error ? ' disabled="disabled"' : '',
];

$TPL_DATA = [
    'PLUGIN_HOME_TITLE'            => $da->get_lang('PLUGIN_HOME_TITLE'),
    'PLUGIN_HOME_DESCRIPTION'      => $da->get_lang('PLUGIN_HOME_DESCRIPTION'),
    'PLUGIN_FOOTER_TITLE'          => sprintf($da->get_lang('PLUGIN_FOOTER_TITLE'), PLUGIN_VERSION),
    'PLUGIN_FOOTER_CLASS'          => ' sr-only',
    'PLUGIN_MONGOADMIN_CLASS'      => ' sr-only',
    'PLUGIN_MONGOADMIN_LINK'       => MONGOADMIN_LINK,
    'PLUGIN_SELECTED_DATABASE'     => (isset($database) && $database) ? $database : ((isset($dbname) && $dbname) ? $dbname : false),
    'PLUGIN_MONGOADMIN_CONNECT'    => $da->get_lang('PLUGIN_CONNECT_MONGOADMIN'),
    'MAIN_CONTENT'                 => _get_tpl(PLUGIN_TPL_DIR . '/'.PLUGIN_ACTION.'.html', $MAIN_CONTENT),
    'SERVER_TIME'                  => date(TIME_DATE_FORMAT),
    'UUID'                         => gen_uuid(),
];

if ($is_error)
{
    $TPL_DATA['DISABLED']             = ' disabled="disabled"';
    $TPL_DATA['MESSAGE_HTML']         = '';
    $TPL_DATA['ERROR_HTML']           = $error_message .': '. ($error_details ? $error_details : $da->get_lang('TRY_AGAIN_LATER'));
}
else
{
    $TPL_DATA['MESSAGE_HTML']         = $message_ok;
    $TPL_DATA['ERROR_HTML']           = '';
}

do_output(generate_page($TPL_DATA));

// terminate here
exit;
