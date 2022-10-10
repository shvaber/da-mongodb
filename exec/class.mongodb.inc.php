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

if (!defined('IN_DA_PLUGIN') || (IN_DA_PLUGIN !==true)){die("You're not allowed to view this page!");}

class mongodb
{
    private $_ERROR=false;
    private $_ERROR_TEXT;

    private $_MONGO_HOST;
    private $_MONGO_PORT;
    private $_MONGO_DB;
    private $_MONGO_USER;
    private $_MONGO_PASSWORD;

    private $_MONGO_CONN;
    private $_MONGO_LAST_ERROR;
    private $_MONGO_QUERIES;

    private $_CONNECT_DB;
    private $_MONGO_PERSISTENT = false;

    private $_systemDBName = 'admin';

    function __construct($input)
    {
        $this->_MONGO_QUERIES = array();
        if ($this->_MONGO_CONN) $this->_disconnect();

        $user = (isset($input['user']) && $input['user']) ? $input['user'] : false;
        $password = (isset($input['password']) && $input['password']) ? $input['password'] : false;
        $dbname = (isset($input['dbname']) && $input['dbname']) ? $input['dbname'] : false;
        $host = (isset($input['host']) && $input['host']) ? $input['host'] : 'localhost';
        $port = (isset($input['port']) && intval($input['port'])) ? intval($input['port']) : 5432;

        $this->setDBuser($user);
        $this->setDBpassword($password);
        $this->setDBhost($host);
        $this->setDBport($port);
        $this->setDBname($dbname);
    }

    // Testing connection to Mongo server
    function testServer()
    {
        $conn = $this->_connect();
        $this->_disconnect();
        return $conn;
    }


    // ================================= GET FUNCTIONS ====================================== \\
    private function getQuery()
    {
        return $this->query;
    }

    private function getDBhost()
    {
        return $this->_MONGO_HOST;
    }

    private function getDBport()
    {
        return $this->_MONGO_PORT;
    }

    private function getDBname()
    {
        return $this->_MONGO_DB;
    }

    private function getDBuser()
    {
        return $this->_MONGO_USER;
    }

    private function getDBpassword()
    {
        return $this->_MONGO_PASSWORD;
    }

    private function runQuery()
    {
        if ($query = $this->getQuery())
        {
            try
            {
                $result = $this->_MONGO_CONN->executeCommand($this->getDBname(), $query);
                $this->setQuery(false);
                return $result;
            }
            catch (MongoDB\Driver\Exception\AuthenticationException $e)
            {
                $this->setQuery(false);
                $this->_MONGO_LAST_ERROR = "Exception:". $e->getMessage(). "\n";
                $this->_ERROR = true;
                $this->_ERROR_TEXT[] = 'Failed to run query: N/A. error: '.$this->_MONGO_LAST_ERROR;
                return false;
            }
            catch (MongoDB\Driver\Exception\ConnectionException $e)
            {
                $this->setQuery(false);
                $this->_MONGO_LAST_ERROR = "Exception:". $e->getMessage(). "\n";
                $this->_ERROR = true;
                $this->_ERROR_TEXT[] = 'Failed to run query: N/A. error: '.$this->_MONGO_LAST_ERROR;
                return false;
            }
            catch (MongoDB\Driver\Exception\ConnectionTimeoutException $e)
            {
                $this->setQuery(false);
                $this->_MONGO_LAST_ERROR = "Exception:". $e->getMessage(). "\n";
                $this->_ERROR = true;
                $this->_ERROR_TEXT[] = 'Failed to run query: N/A. error: '.$this->_MONGO_LAST_ERROR;
                return false;
            }
            catch(MongoDB\Driver\Exception $e)
            {
                $this->setQuery(false);
                $this->_MONGO_LAST_ERROR = "Exception:". $e->getMessage(). "\n";
                $this->_ERROR = true;
                $this->_ERROR_TEXT[] = 'Failed to run query: N/A. error: '.$this->_MONGO_LAST_ERROR;
                return false;
            }
        }
        else
        {
            $this->_ERROR = true;
            $this->_ERROR_TEXT[] = 'Can not run empty query';
            return false;
        }
    }


    // ================================= SET FUNCTIONS ====================================== \\
    private function setQuery($str)
    {
        //if ($str) $this->_MONGO_QUERIES[] = sprintf("[%s][%s]: %s", '' /* DBNAME */, $this->_CONNECT_DB, $str);
        if ($str)
        {
            try
            {
                $this->query = new MongoDB\Driver\Command($str);
            }
            catch(MongoDB\Driver\Exception\CommandException $e)
            {
                echo "Exception:". $e->getMessage(). "\n";
                $this->query = false;
                $this->_MONGO_LAST_ERROR = "Exception:". $e->getMessage(). "\n";
                $this->_ERROR = true;
                $this->_ERROR_TEXT[] = 'Failed to prepare query: N/A. error: '.$this->_MONGO_LAST_ERROR;
                return false;
            }
        }
        else
        {
            $this->query = false;
        }
    }

    private function setDBhost($str)
    {
        $this->_MONGO_HOST = $str;
    }

    private function setDBport($str)
    {
        $this->_MONGO_PORT = $str;
    }

    private function setDBname($str)
    {
        $this->_MONGO_DB = $str;
    }

    private function setDBuser($str)
    {
        $this->_MONGO_USER = $str;
    }

    private function setDBpassword($str)
    {
        $this->_MONGO_PASSWORD = $str;
    }

    private function setPersistent($bool)
    {
        $this->_MONGO_PERSISTENT = ($bool) ? true : false;
    }


    // ================================= MAIN FUNCTIONS ====================================== \\


    //
    // COUNT DATABASES:
    // - for all users, when $owner=false
    // - for a specified owner
    // ========================================
    function getDatabasesCount($owner=false)
    {
        if (!$this->_MONGO_CONN) $this->_connect();

        if ($this->_MONGO_CONN)
        {
            if ($databases = $this->getDatabasesList($owner))
            {
                return count($databases);
            }
            else
            {
                $this->_disconnect();
                $this->_ERROR = true;
                $this->_ERROR_TEXT[] = 'Failed to count databases';
                return false;
            }
        }
        $this->_ERROR = true;
        $this->_ERROR_TEXT[] = 'Failed to connect to MongoDB server';
        return false;
    }

    //
    // GET SIZE OF DATABASES:
    // - for all users, when $owner=false
    // - for a specified owner
    // ========================================
    function getDatabasesSize($owner=false)
    {
        if (!$this->_MONGO_CONN) $this->_connect();

        if ($this->_MONGO_CONN)
        {
            if ($databases = $this->getDatabasesList($owner))
            {
                $size = 0;
                foreach ($databases as $db)
                {
                    $size += $db['size'];
                }
                return intval($size);
            }
            else
            {
                $this->_disconnect();
                $this->_ERROR = true;
                $this->_ERROR_TEXT[] = 'Failed to get size of databases';
                return false;
            }
        }
        $this->_ERROR = true;
        $this->_ERROR_TEXT[] = 'Failed to connect to MongoDB server';
        return false;
    }

    //
    // LIST USERS:
    // - for all users, when $user=false
    // - for a specified owner
    // ========================================
    function getUsersList($user=false)
    {
        $this->setDBname($this->_systemDBName);
        $system_users = ['admin','diradmin','root'];

        if (!$this->_MONGO_CONN) $this->_connect();

        if ($this->_MONGO_CONN)
        {
            $command = ["usersInfo" => ["forAllDBs" => true]];
            $this->setQuery($command);
            if ($result = $this->runQuery())
            {
                $data = false;
                $id = 1;
                $users = current($result->toArray())->users;
                foreach($users as $a => $row)
                {
                    $dbuser = $row->user;
                    if ($user)
                    {
                        if ((!in_array($dbuser, $system_users)) && (strpos($dbuser,'_')!==false))
                        {
                            $dbowner = substr($dbuser,0,strpos($dbuser,'_'));
                            if ($user === $dbowner)
                            {
                                $data[] = $dbuser;
                            }
                        }
                    }
                    else
                    {
                        $data[] = $dbuser;
                    }
                }
                return $data;
            }
            else
            {
                $this->_disconnect();
                $this->_ERROR = true;
                $this->_ERROR_TEXT[] = 'Failed to get list of users';
                return false;
            }
        }
        $this->_ERROR = true;
        $this->_ERROR_TEXT[] = 'Failed to connect to MongoDB server';
        return false;
    }

    //
    // get list of users for a specific database
    // ==================================================
    function getPrivilegesList($dbase)
    {
        $this->setDBname($dbase);
        $system_users = ['admin','diradmin','root'];

        if (!$this->_MONGO_CONN) $this->_connect();

        if ($this->_MONGO_CONN)
        {
            $command = ["usersInfo" => 1];
            $this->setQuery($command);
            if ($result = $this->runQuery())
            {
                $data = false;
                $id = 1;
                $users = current($result->toArray())->users;
                foreach($users as $a => $row)
                {
                    $user = $row->user;
                    if (!in_array($user, $system_users))
                    {
                        $data[] = [
                            'id'             => $id,
                            'user'           => $user,
                            'password'       => true,
                            'privileges'     => '',
                        ];
                        $id++;
                    }
                }
                return $data;
            }
            else
            {
                $this->_disconnect();
                $this->_ERROR = true;
                $this->_ERROR_TEXT[] = 'Failed to get list of users';
                return false;
            }
        }
        $this->_ERROR = true;
        $this->_ERROR_TEXT[] = 'Failed to connect to MongoDB server';
        return false;
    }

    //
    // LIST DATABASES:
    // - for all users, when $owner=false
    // - for a specified owner
    // ========================================
    function getDatabasesList($owner=false)
    {
        $system_databases = ['admin','config','local'];

        if (!$this->_MONGO_CONN) $this->_connect();

        if ($this->_MONGO_CONN)
        {
            $command = ["listDatabases" => 1];
            /*
            if ($owner)
            {
                $mongoRegex = new MongoDB\BSON\Regex("/^$work_/", "name");
                $command["filter"] = $mongoRegex;
            }
            */
            $this->setQuery($command);
            if ($result = $this->runQuery())
            {
                $data = false;
                $id = 1;
                $databases = current($result->toArray())->databases;
                foreach($databases as $a => $row)
                {
                    $dbname = $row->name;
                    $dbowner = 'system';
                    if ((!in_array($dbname, $system_databases)) && (strpos($dbname,'_')!==false))
                    {
                        $dbowner = substr($dbname,0,strpos($dbname,'_'));
                    }
                    if ($owner)
                    {
                        if ($dbowner !== $owner) continue;
                    }
                    $data[] = [
                        'id'    => $id,
                        'name'  => $dbname,
                        'owner' => $dbowner,
                        'size'  => $row->sizeOnDisk,
                        'empty' => $row->empty,
                        ];
                    $id++;
                }
                return $data;
            }
            else
            {
                $this->_disconnect();
                $this->_ERROR = true;
                $this->_ERROR_TEXT[] = 'Failed to get list of databases';
                return false;
            }
        }
        $this->_ERROR = true;
        $this->_ERROR_TEXT[] = 'Failed to connect to MongoDB server';
        return false;
    }

    //
    // DELETE A DATABASE
    // ==================================================
    function doDeleteDB($dbname)
    {
        if (!$this->_MONGO_CONN) $this->_connect();

        if ($this->_MONGO_CONN)
        {
            $this->setDBname($dbname);

            $command = ["dropDatabase" => 1];
            $this->setQuery($command);
            if ($result = $this->runQuery())
            {
                return $result;
            }
            else
            {
                $this->_disconnect();
                $this->_ERROR = true;
                $this->_ERROR_TEXT[] = 'Failed to drop a database';
                return false;
            }
        }
        $this->_ERROR = true;
        $this->_ERROR_TEXT[] = 'Failed to connect to MongoDB server';
        return false;
    }

    function grantRole2Role()
    {
        if (!$this->_MONGO_CONN) $this->_connect();

        if ($this->_MONGO_CONN)
        {
        }
    }

    function grantRole2Database()
    {
        if (!$this->_MONGO_CONN) $this->_connect();

        if ($this->_MONGO_CONN)
        {
        }
    }

    function createDatabase($dbname, $dbuser)
    {
        if (!$this->_MONGO_CONN) $this->_connect();

        if ($this->_MONGO_CONN)
        {
            $this->setDBname($dbname);

            $bulk = new MongoDB\Driver\BulkWrite;
            $doc = [
                'date'    => date('r'),
                'creator' => PLUGIN_NAME,
                'tag'     => 'system data',
            ];
            $bulk->insert($doc);
            $result = $this->_MONGO_CONN->executeBulkWrite($dbname.'._System', $bulk);

            //call MongoDB::command to create 'dbname' database
            if ($result)
            {
                return $result;
            }
            else
            {
                $this->_disconnect();
                $this->_ERROR = true;
                $this->_ERROR_TEXT[] = 'Failed to create a database';
                return false;
            }
        }
        $this->_ERROR = true;
        $this->_ERROR_TEXT[] = 'Failed to create a database';
        return false;
    }


    //
    // ADD USER TO DB
    // ===========================================
    function grantUserOnDB($dbuser, $dbname)
    {
        if (!$this->_MONGO_CONN) $this->_connect();

        if ($this->_MONGO_CONN)
        {
            $command = [
                        "updateUser" => $dbuser,
                        "roles"      => [
                                        ["role" => "readWrite", "db" => $dbname]
                                    ]
                                ];
            $this->setDBname($dbname);
            $this->setQuery($command);
            $result = $this->runQuery();
            if ($result)
            {
                return $result;
            }
            else
            {
                $this->_disconnect();
                $this->_ERROR = true;
                $this->_ERROR_TEXT[] = 'Failed to add user to DB';
                return false;
            }
        }
        $this->_ERROR = true;
        $this->_ERROR_TEXT[] = 'Failed to add user to DB';
        return false;
    }


    //
    // CHANGE A PASSWORD
    // ===========================================
    function changeUserPassword($dbuser, $dbpass, $dbname)
    {
        if (!$this->_MONGO_CONN) $this->_connect();

        if ($this->_MONGO_CONN)
        {
            $command = [
                    "updateUser" => $dbuser,
                    "pwd" => $dbpass
                    ];
            $this->setDBname($dbname);
            $this->setQuery($command);
            $result = $this->runQuery();
            if ($result)
            {
                return $result;
            }
            else
            {
                $this->_disconnect();
                $this->_ERROR = true;
                $this->_ERROR_TEXT[] = 'Failed to change an user password';
                return false;
            }
        }
        $this->_ERROR = true;
        $this->_ERROR_TEXT[] = 'Failed to change an user password';
        return false;
    }


    //
    // DROP USER
    // ============================================
    function removeUser($dbuser, $dbname)
    {
        if (!$this->_MONGO_CONN) $this->_connect();

        if ($this->_MONGO_CONN)
        {
            $command = ["dropUser" => $dbuser];
            $this->setDBname($dbname);
            $this->setQuery($command);
            $result = $this->runQuery();
            if ($result)
            {
                return $result;
            }
            else
            {
                $this->_disconnect();
                $this->_ERROR = true;
                $this->_ERROR_TEXT[] = 'Failed to remove an user';
                return false;
            }
        }
        $this->_ERROR = true;
        $this->_ERROR_TEXT[] = 'Failed to remove an user';
        return false;
    }


    function createUser($dbuser, $dbpass, $dbname)
    {
        if (!$this->_MONGO_CONN) $this->_connect();

        if ($this->_MONGO_CONN)
        {
            //command to create a new user
            $command = [
                        "createUser" => $dbuser,
                        "pwd"        => $dbpass,
                        "roles"      => [
                                        ["role" => "readWrite", "db" => $dbname]
                                    ]
                                ];
            $this->setDBname($dbname);
            $this->setQuery($command);

            //call MongoDB::command to create user in 'dbname' database
            $result = $this->runQuery();
            if ($result)
            {
                //var_dump($result);
                return $result;
            }
            else
            {
                $this->_disconnect();
                $this->_ERROR = true;
                $this->_ERROR_TEXT[] = 'Failed to create a role';
                return false;
            }
        }
        $this->_ERROR = true;
        $this->_ERROR_TEXT[] = 'Failed to create a role';
        return false;
    }

    private function _connect()
    {
        $conn = false;
        $user = $this->getDBuser();
        $password = $this->getDBpassword();
        $host = $this->getDBhost();
        $port = $this->getDBport();
        $dbname = $this->getDBname();

        if ($user && $password && $host)
        {
            $this->_CONNECT_DB = "mongodb://".$user;
            if ($password) $this->_CONNECT_DB .= ":". $password;
            if ($host) $this->_CONNECT_DB .= "@". $host;
            if ($port) $this->_CONNECT_DB .= ":". intval($port);
            if ($dbname && ($dbname !== '*')) $this->_CONNECT_DB .= "/". $dbname;
            $conn = new MongoDB\Driver\Manager($this->_CONNECT_DB);
        }
        $this->_MONGO_CONN=$conn;
        return $this->_MONGO_CONN;
    }

    private function _disconnect($force=false)
    {
        // The new driver is designed to leave connections open, and there is no method of turning that off.
        return true;
    }
}

// END
