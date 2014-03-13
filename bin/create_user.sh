#!/bin/bash

_HOSTS=""
_USER=""
_PUBKEY=""
_UID=""
_GROUP=""
SHADOW=""
SSH_OPTIONS=""

usage() {
    echo "
Usage: $0
  --help               Display this help message
  -h, --hosts          Login host(space separated values)
  -u, --user           Username
  -k, --pubkey         Public key(string or file path)
  -i, --uid            UID
  [-g, --group]        Group
  [-p, --shadow]       Hash in /etc/shadow (single quotation marks)
  [-s, --ssh_dir]      Path to .ssh
  [-o, --ssh_options]  Ssh options
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
            '-k'|'--pubkey' )
                if [ -f "$2" ] ; then
                    _PUBKEY=`cat $2`
                else
                    _PUBKEY="$2"
                fi
                
                shift 2
                ;;
            '-i'|'--uid' )
                _UID="$2"
                shift 2
                ;;
            '-g'|'--group' )
                _GROUP="$2"
                shift 2
                ;;
            '-p'|'--shadow' )
                SHADOW="$2"
                shift 2
                ;;
            '-s'|'--ssh_dir' )
                SSH_DIR="$2"
                shift 2
                ;;
            '-o'|'--ssh_options' )
                SSH_OPTIONS="$2"
                shift 2
                ;;
        esac
    done
}

create_user() {
    if [ "$SSH_DIR" == "" ] ; then
        SSH_DIR=/home/$_USER/.ssh
    fi
    
    AUTHORIZED_KEYS=$SSH_DIR/authorized_keys
    
    HASH=`cat /dev/urandom | LC_CTYPE=C tr -dc "[:alnum:]" | head -c 32`
    TMP_SHELL=/tmp/${HASH}.sh
    
    SSH_OPTIONS=`bash -c "echo $SSH_OPTIONS"`

    cat << EOF | ssh $SSH_OPTIONS $_HOST "cat >> ${TMP_SHELL}"
#!/bin/bash

if getent passwd | awk -F':' '{ print \$1}' | grep -w $_USER > /dev/null 2>&1; then
    echo "[${_HOST}] ${_USER} is already registered"
    exit 1
fi

if ! awk -F':' '{ print \$1}' /etc/group | grep $_GID > /dev/null 2>&1 ; then
    _GROUP=$_USER
fi

if [ "$SHADOW" == "" ] ; then
    HASH='\$6\$'\`sha1sum <(date) | awk '{print \$1}'\`
    SHADOW=\`python -c "import crypt; print crypt.crypt(\"${_USER}\", \"\${HASH}\")";\`
fi

/usr/sbin/useradd -u $_UID -g $_GROUP -p '$SHADOW' -m $_USER

sed -i -e "s/${_USER}:\!\!/${_USER}:\${SHADOW}/" /etc/shadow
echo '${_USER}    ALL=(ALL)       ALL' >> /etc/sudoers
mkdir -m 700 $SSH_DIR
echo '${_PUBKEY}' >> $AUTHORIZED_KEYS
chmod 600 $AUTHORIZED_KEYS
chown $_USER:$_GROUP $SSH_DIR $AUTHORIZED_KEYS
EOF

    ssh $SSH_OPTIONS -t -t $_HOST "chmod +x ${TMP_SHELL}; sudo $TMP_SHELL; rm -f $TMP_SHELL"
}

BIN_PATH=$(cd $(dirname $0); pwd)
SSH_CONF=$BIN_PATH/../config/ssh_config
KNOWN_HOSTS=$BIN_PATH/../tmp/known_hosts

get_options "$@" --ssh_options "-F ${SSH_CONF} -o UserKnownHostsFile=${KNOWN_HOSTS} ${SSH_OPTIONS}"

SERVERS=${_HOSTS:-"server1 server2"}

for SERVER in $SERVERS; do
    _HOST=$SERVER
    create_user 
done

rm -f $KNOWN_HOSTS
