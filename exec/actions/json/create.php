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

$created=false;

if (isset($_POST) && $_POST)
{
    $dbuser = (isset($_POST['dbuser']) && $_POST['dbuser']) ? $USER ."_". $_POST['dbuser'] : false;
    $dbname = (isset($_POST['dbname']) && $_POST['dbname']) ? $USER ."_". $_POST['dbname'] : false;
    $dbpass = (isset($_POST['dbpass']) && $_POST['dbpass']) ? trim($_POST['dbpass']) : false;
    $dbowner = false;

    // DOES AN USER'S PACKAGE HAVE ENOUGH CAPACITY?
    if (($MONGO_USER_USAGE === $MONGO_USER_LIMIT) || ($MONGO_USER_USAGE > $MONGO_USER_LIMIT))
    {
        $is_error = true;
        $error_message = $da->get_lang('ERROR_MESSAGE_MONGODB_LIMIT_HIT');
        $error_details = $da->get_lang('ERROR_DETAILS_MONGODB_LIMIT_HIT');
        $action_file = sprintf("%s/%s/%s.php", PLUGIN_ACTION_DIR, FILE_TYPE, 'error');
        return;
    }
    else
    {
        if ($mongodb->testServer())
        {
            $mongodb_dbusers = $mongodb->getUsersList($USER);

            if (!in_array($USER, $mongodb_dbusers))
            {
                $session_password = false;
                $da_sess_data = array();
                $da_sess_file = '/usr/local/directadmin/data/sessions/da_sess_'. $_SERVER['SESSION_ID'];
                if (is_file($da_sess_file) && ($da_sess_data = parse_ini_file($da_sess_file)))
                {
                    $session_username = (isset($da_sess_data['username']) && $da_sess_data['username']) ? $da_sess_data['username'] : false;
                    $session_password = (isset($da_sess_data['passwd']) && $da_sess_data['passwd']) ? base64_decode($da_sess_data['passwd']) : false;
                    if ($session_password && $session_username && ($session_username == $USER))
                    {
                        // Create a system MONGO user with system password
                        $mongodb->createUser($USER, $session_password, $dbname);
                    }
                    else
                    {
                        // case 1: Username is empty - `login-as` is used
                        // case 2: Password is empty - a hacking attempt?

                        // Create a system MONGO user with a random password
                        $session_password = randomPassword();
                        $mongodb->createUser($USER, $session_password, $dbname);
                    }
                }
                else
                {
                    // Create a system MONGO user with a random password
                    $session_password = randomPassword();
                    $mongodb->createUser($USER, $session_password, $dbname);
                }
                _save_user_credentials($sso_config_file, [
                    'dbhost' => MONGO_HOST,
                    'dbport' => MONGO_PORT,
                    'dbname' => '*',
                    'dbuser' => $USER,
                    'dbpass' => $session_password
                ]);

            }

            // Is dbuser the same as dbname?
            if ($dbname == $dbuser)
            {
                // dbuser is the same as dbname
                // we do not need to create a separate role in this case
                $dbowner = $dbuser;
                $dbowner_passwd = $dbpass;
                if (!in_array($dbuser, $mongodb_dbusers)) $mongodb->createUser($dbuser, $dbpass, $dbname);
                $created = $mongodb->createDatabase($dbname, $dbowner);
                $mongodb->grantRole2Role($dbowner, $USER);
            }
            else
            {
                // dbuser is NOT the same as dbname
                // we need to create a separate role in this case
                $dbowner = $dbname;
                $dbowner_passwd = false;
                if (!in_array($dbowner, $mongodb_dbusers)) $mongodb->createUser($dbowner, $dbowner_passwd, $dbname);
                if (!in_array($dbuser, $mongodb_dbusers)) $mongodb->createUser($dbuser, $dbpass, $dbname);
                $created = $mongodb->createDatabase($dbname, $dbowner);
                $mongodb->grantRole2Role($dbowner, $USER);
                $mongodb->grantRole2Role($dbowner, $dbuser);
                $mongodb->grantRole2Database($dbuser, $dbname);
            }
            //var_dump($mongodb->getQueries());
        }
    }
}

if ($created !== false)
{
    $is_error = false;
    $error_message = false;
    $error_details = false;
    $message_ok = sprintf($da->get_lang('OK_MESSAGE_CREATED_DB'), $dbuser, $dbpass, $dbname, MONGO_HOST, MONGO_PORT);
}
else
{
    $is_error = true;
    $error_message = $da->get_lang('ERROR_MESSAGE_FAILED_CREATE_DB');
    $error_details = $da->get_lang('ERROR_DETAILS_FAILED_CREATE_DB') . "<br>Details: ". $mongodb->getLastError();
}

//var_dump($mongodb->getErrors(), $mongodb->getQueries);
