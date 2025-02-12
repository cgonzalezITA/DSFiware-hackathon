#!/bin/bash
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi
BASEDIR=$(dirname "$SCRIPTNAME")
VERBOSE=true
SUBMODULE=""

. $BASEDIR/_base.sh
SCRIPTNAME=$BASH_SOURCE

unset DID1
#---------------------------------------------- main program ------------------------
echo "##############################"
echo "# Install the DSFiware-hackathon github repository"
DSFIWAREHOL_GH_HTTPS="https://github.com/cgonzalezITA/DSFiware-hackathon.git"
DSFIWAREHOL_TAG="phase03.step04"
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

echo "# $DSFIWAREHOL_TAG-Deployment of the VCIssuer (Keycloak)"
NAMESPACE="consumer"

# DSFIWAREHOL_FOLDER="DSFiware-hackathon" # TODO DELETE
echo "# Jumping into the hackathon folder ($DSFIWAREHOL_FOLDER)"
cd $DSFIWAREHOL_FOLDER
echo "Now at $(pwd) folder"

echo "# Removes previously existing namespace %$NAMESPACE"
kRemoveRestart ns $NAMESPACE -y -v
echo "# Deployment of the VCIssuer (Keycloak)"
hFileCommand consumer -f key r -v -y -b

echo "# Remove the previously used route ROUTE_DEMO_JSON"
. scripts/manageAPI6Routes.sh delete -r ROUTE_DEMO_JSON

echo "# Register the VCIssuer endpoint"
. scripts/manageAPI6Routes.sh insert -r ROUTE_CONSUMER_KEYCLOAK_fiwaredsc_consumer_local

echo "# Registers the fiwaredsc-consumer.local at the /etc/hosts file to map the DNS with the IP address"
PUBLIC_IP=$(hostname -I | awk '{print $1}')
DNS_CONSUMER="fiwaredsc-consumer.local"
LINE="$PUBLIC_IP  fiwaredsc-trustanchor.local fiwaredsc-consumer.local fiwaredsc-provider.local"
echo "# Map the local DNS at your hosts file"
MSG="# To use the local DNSs at the host, it is required to add a few lines to the '/etc/hosts' file:\n\
$LINE\n
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
    Press a key to continue" "" 10 false false



# Waits for the deployment
wait4PodsDeploymentCompleted $NAMESPACE 20 "Keycloak may take a while to be available, so please, wait a few seconds after its status is (1/1)"

echo "# Verification"
CMD="curl -s -o /dev/null -w \"%{http_code}\" -k https://$DNS_CONSUMER/realms/consumerRealm/account/oid4vci"
RC=$($CMD)
echo -e "\nRC=$RC"
if [[ "$RC" == "\"200\"" ]]; then
    readAnswer "\"https://$DNS_CONSUMER\" has worked! Congrats!. Now a VC will be issued for a user with ORDERCONSUMER role" "" 5 false

    echo "Script $SCRIPTNAME Continues issuing a VC"
    VERIFIABLE_CREDENTIAL=$(scripts/issueVC_operator-credential-orderProducer.sh)

    echo "# Verification. Does VERIFIABLE_CREDENTIAL exists?"
    if [[ "${#VERIFIABLE_CREDENTIAL}" -gt  0 ]]; then
        if echo "$VERIFIABLE_CREDENTIAL" | grep -Eq '^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$'; then
            echo "The VERIFIABLE_CREDENTIAL contains a JWT."
            HEADER=$(echo "$VERIFIABLE_CREDENTIAL" | cut -d '.' -f1 | base64 -d 2>/dev/null)
            PAYLOAD=$(echo "$VERIFIABLE_CREDENTIAL" | cut -d '.' -f2 | base64 -d 2>/dev/null)
            if echo "$HEADER" | jq . >/dev/null 2>&1 && echo "$PAYLOAD" | jq . >/dev/null 2>&1; then
                echo "The VERIFIABLE_CREDENTIAL contains a valid JWT."
                readAnswer "\"https://$DNS_CONSUMER\" has worked. VC VERIFIABLE_CREDENTIAL has been properly generated for the user with ORDERCONSUMER role. \
                You can verify it is a valid JWT at https://jwt.io/
                $VERIFIABLE_CREDENTIAL\nCongrats!" "" 5 false
            else
                echo "The variable contains an invalid JWT."
            fi
        else
            echo "The VERIFIABLE_CREDENTIAL does not contain a valid JWT format."
        fi
    else
        readAnswer "\"https://$DNS_CONSUMER\" has been unable to issue a VC VERIFIABLE_CREDENTIAL. Review the logs and the value file used by helm for some clues" "" 15 false
    fi

    echo "Script $SCRIPTNAME has finished"
else
    readAnswer "\"https://$DNS_CONSUMER\" has failed (RC=$RC). Review the logs and the value file used by helm for some clues" "" 15 false
fi

cd ..
