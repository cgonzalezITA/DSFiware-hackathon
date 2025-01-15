#!/bin/bash
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi
BASEDIR=$(dirname "$SCRIPTNAME")
VERBOSE=true
SUBMODULE=""

. $BASEDIR/_base.sh
SCRIPTNAME=$BASH_SOURCE

echo "# Registers the DNSs used by the dsQuickInstall* scripts at the '/etc/hosts' file to map them with the host IP address"
PUBLIC_IP=$(hostname -I | awk '{print $1}')
LINE="$PUBLIC_IP  fiwaredsc-trustanchor.local fiwaredsc-consumer.local fiwaredsc-provider.local fiwaredsc-api6dashboard.local"
MSG="# To use the local DNSs at the host, it is required to add the following line to the '/etc/hosts' file:\n\
$LINE\n
Do you want to insert it automatically?";
if [ $(readAnswer "$MSG (y*|n)" 'y' 30) == 'y' ]; then
    cat <<EOF >> /etc/hosts
# local DNS used by the https://github.com/cgonzalezITA/DSFiware-hackathon repository
$LINE
EOF
    if [[ "$?" -ne 0 ]]; then
        readAnswer "An error has happened. This operation requires sudo permission. Press any key to continue" \
            "" 5 false false
    else
        echo "To access them from a windows browser, add the same line to the 'C:\Windows\System32\drivers\etc\hosts' file."
        readAnswer "Press any key to review the /etc/hosts file" "" 5 false false
        cat /etc/hosts
    fi
fi
