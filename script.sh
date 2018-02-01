#!/bin/bash
config_file_path=$1         # path of the configuration file
pre_or_post=$2              # PreBackup, PostBackup

# variables used for returning the status of the scripts
success=0
error=1
warning=2
status=$success

log_path="$log_destination/config_error.log"   #path of log file
#loading user configuration file to access reqired parameters


if [ $pre_or_post -eq "0" ]; then
>$log_path
chmod 777 $log_path
fi

if [ -a $config_file_path ] ;
    then . $config_file_path
    ret=$?
    if [ $ret -ne "0" ]
    then
        printf "ERROR : unable to execute configuration file.\n">>$log_path
        exit $error
    else
        printf "Configuration file successfully executed.\n">>$log_path
    fi
else
    printf "ERROR : configuration file does not exist.\n">>$log_path
    exit $error
fi

no_of_databases=${#oracle_sid[@]}
current_database_index=0

#managing  logs files
function manage_log(){
if [ $pre_or_post -eq "0" ]; then
    log_path="$log_destination/pre-script_$ORACLE_SID.log"
    printf  "Running pre-script for $ORACLE_SID\n">$log_path
else
    log_path="$log_destination/post-script_$ORACLE_SID.log"
    printf  "Running post-script for $ORACLE_SID \n">$log_path
fi
chmod 777 $log_path
}

#setting oracle environment variables
function set_parameters(){
        export ORACLE_HOME=${oracle_home[current_database_index]};
        export ORACLE_SID=${oracle_sid[current_database_index]};
}


#finding the status of pre-script execution
function status_pre_script(){
    if ! grep "Database altered" "$log_path" >/dev/null ;
    then
		if grep "ORACLE not available" "$log_path" >/dev/null || grep "database not open" "$log_path" >/dev/null || grep "already in backup" "$log_path" >/dev/null
		then
				if [ $status != $error ] ; then
			status=$warning
				fi
		else
			status=$error
		fi
	fi
}

function pre_script(){
        #change current log
        #put database in begin backup mode
        su oracle -c "$ORACLE_HOME/bin/sqlplus \" /  as sysdba\""<<_EOF_
        spool $log_path APPEND;
        ALTER SYSTEM ARCHIVE LOG CURRENT;
        spool off

        spool $log_path APPEND;
        alter database begin backup;
        spool off;
_EOF_
#function calls
status_pre_script
}

#finding the status of post-script execution
function status_post_script(){
    if ! grep "Database altered" "$log_path" >/dev/null ;
    then
        if grep "ORACLE not available" "$log_path" >/dev/null || grep "none of the files are in backup" "$log_path" >/dev/null
        then
        if [ $status != $error ] ; then
            status=$warning
        fi
        else
            status=$error
        fi
    fi
}

#putting database out of backup mode
function post_script(){
    su oracle -c "$ORACLE_HOME/bin/sqlplus \" /  as sysdba\""<<_EOF_
    spool $log_path APPEND;
    alter database end backup;
    spool off;
_EOF_
status_post_script
}

#check for system privilege
if [ "$(id -u)" -eq "0" ]; then
    if [ $pre_or_post -eq "0" ];
    then #check for which script(pre/post) to execute
        >$log_destination/pre_script.log
        chmod 777 $log_destination/pre_script.log
        
        for (( current_database_index=0; current_database_index<$no_of_databases ; current_database_index++ ))
        do
            set_parameters
            manage_log
            pre_script
            printf  "pre-script execution completed.\n" >>$log_path
           cat $log_path>>$log_destination/pre_script.log
            rm -f $log_path
        done
        exit $status
    else
        >$log_destination/post_script.log;
        chmod 777 $log_destination/post_script.log;
        for (( current_database_index=0; current_database_index<$no_of_databases ; current_database_index++ ))
        do
            set_parameters
            manage_log
            post_script
            printf  "post-script execution completed.\n" >>$log_path
           cat  $log_path>>$log_destination/post_script.log
            rm -f $log_path
        done
        exit $status
    fi
else
    printf  'ERROR : Need system privilege .\n'>>$log_path
    exit $error
fi
