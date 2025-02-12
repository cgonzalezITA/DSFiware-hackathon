#!/bin/bash
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi
BASEDIR=$(dirname "$SCRIPTNAME")
VERBOSE=true
SUBMODULE=""

. $BASEDIR/_base.sh
SCRIPTNAME=$BASH_SOURCE

#---------------------------------------------- main program ------------------------
echo "##############################"
echo "# Install the DSFiware-hackathon github repository"
DSFIWAREHOL_GH_HTTPS="https://github.com/cgonzalezITA/DSFiware-hackathon.git"
DSFIWAREHOL_TAG="phase01.step03"
DSFIWAREHOL_FOLDER="DSFiware-hackathon-$DSFIWAREHOL_TAG"
REPLY='y'
if [[ -d $DSFIWAREHOL_FOLDER ]]; then
    REPLY=$(readAnswer  "Folder $DSFIWAREHOL_FOLDER already exists. Do you want to delete it to reinstall the DSFiware-hackathon git? (Y|n*)" \
        'n');
    [[ $REPLY == 'y' ]] && sudo rm -r $DSFIWAREHOL_FOLDER;
fi
if [[ $REPLY == 'y' ]]; then
    CMD="git clone $DSFIWAREHOL_GH_HTTPS $DSFIWAREHOL_FOLDER -b $DSFIWAREHOL_TAG"
    echo "Running CMD=$CMD"
    bash -c "$CMD"
fi

echo "# $DSFIWAREHOL_TAG-Deploy a new route via the Apisix.yaml file"
NAMESPACE="apisix"

# DSFIWAREHOL_FOLDER="DSFiware-hackathon1" # TODELETE
echo "# Jumping into the hackathon folder ($DSFIWAREHOL_FOLDER)"
cd $DSFIWAREHOL_FOLDER
echo "Now at $(pwd) folder"


PUBLIC_IP=$(hostname -I | awk '{print $1}')
DNS_APISIX="fiwaredsc-api6dashboard.local"
LINE="$PUBLIC_IP  $DNS_APISIX"
echo "# Map the local DNS at your hosts file"
MSG="# To use the DNS $DNS_APISIX at the host, it is required to add a new line \"$LINE\" to the '/etc/hosts' file.\n\
Do you want to insert it automatically?";
if [ $(readAnswer "$MSG (y|n*)" 'n') == 'y' ]; then
    sudo cat <<EOF >> /etc/hosts
$LINE
EOF
    if [[ "$?" -ne 0 ]]; then
        readAnswer "An error has happened. This operation requires sudo permission. Do it manually on another terminal and press any key to continue" \
            "" 120 false false
    fi
fi
readAnswer "To access it from a windows browser, add the same line into the 'C:\Windows\System32\drivers\etc\hosts' file\n\
    Press a key to continue" "" 20 false false

echo "# Deploying the apisix helm..."
ARTIFACT_NAME=apisix
hFileCommand $ARTIFACT_NAME -v -y -b restart

readAnswer "On the next screen wait until all the artifacts are properly deployed (1/1)  then press Ctrl+C and the process will continue. Even once available, the initialization of the apisix-data-plane can take several seconds, so be patient" "" 20 false
kGet -w -v -n $NAMESPACE

CMD="curl -s -o /dev/null -w \"%{http_code}\" -k https://$DNS_APISIX"
echo "# Running CMD=$CMD"
RC=$($CMD)
echo "RC=$RC"
if [[ "$RC" == "\"200\"" ]]; then
    echo "It has worked! This is the end of $DSFIWAREHOL_TAG. Congrats!"
    echo "Now you can try it running command \"curl -k https://$DNS_APISIX\""
    SECRET=$(kSecret-show -n api apisix-dashboard-secrets -f apisix-dashboard-secret -v)
    echo "Better to open it at a browser using \"user;$SECRET\"";
else
    echo "It seems that something has failed (RC=$RC). You can wait some minutes and test again the command \"curl -k https://$DNS_APISIX\", else review the logs for some clues"
fi
echo "Script $SCRIPTNAME has finished"
cd ..
