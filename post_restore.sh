#!/bin/bash
config_file_path=$1         # path of the configuration file
. $config_file_path

no_of_databases=${#oracle_sid[@]}
current_database_index=0

function set_parameters(){
        export ORACLE_HOME=${oracle_home[current_database_index]};
        export ORACLE_SID=${oracle_sid[current_database_index]};
}

function post_script(){
    su oracle -c "$ORACLE_HOME/bin/sqlplus \" /  as sysdba\""<<_EOF_
    spool $log_path APPEND;
    startup mount;
    alter database end backup;
    alter database open upgrade;
    spool off;
_EOF_

}

#check for system privilege
if [ "$(id -u)" -eq "0" ]; then
    for (( current_database_index=0; current_database_index<$no_of_databases ; current_database_index++ ))
    do
        set_parameters
        log_path="$log_destination/post-restore_$ORACLE_SID.log"
        printf  'Running post-recovery script\n'>$log_path
        chmod 777 $log_path

        post_script
        printf  "post-restore script execution completed.\n" >>$log_path
    done
else
    echo  "ERROR : Need system privilege" >$log_destination/post-restore.log
fi
