#!/bin/bash

_HOSTS=""
_USER=""
DELETE_HOME_DIR=""
SSH_OPTIONS=""

usage() {
    echo "
Usage: $0
  --help                Display this help message
  -h, --hosts           Login host(space separated values)
  -u, --user            Username
  [-d, --delete_option] Delete home directory 
  [-o, --ssh_options]   Ssh options
"
}

get_options() {
    for OPT in "$@"
    do
        case "$OPT" in
            '--help' )
                usage
                exit 1
                ;;
            '-h'|'--hosts' )
                _HOSTS="$2"
                shift 2
                ;;
            '-u'|'--user' )
                _USER="$2"
                shift 2
                ;;
            '-d'|'--delete_option' )
                DELETE_HOME_DIR="-r"
                shift 1
                ;;
            '-o'|'--ssh_options' )
                SSH_OPTIONS="$2"
                shift 2
                ;;
        esac
    done
}

delete_user() {
   ssh $SSH_OPTIONS -t -t $_HOST "getent passwd | awk -F':' '{ print \$1}' | grep -w $_USER > /dev/null 2>&1 && sudo /usr/sbin/userdel ${DELETE_HOME_DIR} ${_USER}"
}

BIN_PATH=$(cd $(dirname $0); pwd)
SSH_CONF=$BIN_PATH/../config/ssh_config
KNOWN_HOSTS=$BIN_PATH/../tmp/known_hosts

get_options "$@" --ssh_options "-F ${SSH_CONF} -o UserKnownHostsFile=${KNOWN_HOSTS}"

SERVERS=${_HOSTS:-"server1 server2"}

for SERVER in $SERVERS; do
    _HOST=$SERVER
    delete_user
done

rm -f $KNOWN_HOSTS
