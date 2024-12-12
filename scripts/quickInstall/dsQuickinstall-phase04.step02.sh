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
DSFIWAREHOL_TAG="phase04.step02"
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

echo "# $DSFIWAREHOL_TAG-Deployment of the provider's common an authentication components"
NAMESPACE="provider"

# DSFIWAREHOL_FOLDER="DSFiware-hackathon" # TODO DELETE
echo "# Jumping into the hackathon folder ($DSFIWAREHOL_FOLDER)"
cd $DSFIWAREHOL_FOLDER
echo "Now at $(pwd) folder"

echo "# Upgrade the apisix configuration"
kRemoveRestart -n apisix data-plane -v -y
hFileCommand apisix upgrade -b -v -y


echo "# Removes previously existing namespace $NAMESPACE"
kRemoveRestart ns $NAMESPACE -y -v
echo "# Deployment of the provider common"
hFileCommand provider/common r -v -y -b
echo "# Deployment of the provider authentication"
hFileCommand provider/authentication r -v -y -b


echo "# Registration of the new apisix routes"
. scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_OIDC_fiwaredsc_vcverifier_local
. scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_JWKS_fiwaredsc_vcverifier_local
. scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_OIDC_Service_fiwaredsc_vcverifier_local

echo "# Registers the fiwaredsc-provider.local at the /etc/hosts file to map the DNS with the IP address"
PUBLIC_IP=$(hostname -I | awk '{print $1}')
DNS_PROVIDER="fiwaredsc-provider.local"
LINE="$PUBLIC_IP  $DNS_PROVIDER"
echo "# Map the local DNS at your hosts file"
MSG="# To use the DNS $DNS_PROVIDER at the host, it is required to add a new line \"$LINE\" to the '/etc/hosts' file.\n\
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
wait4PodsDeploymentCompleted $NAMESPACE 20

echo "# Verification"
DNS="https://$DNS_PROVIDER/services/hackathon-service/.well-known/openid-configuration"
CMD="curl -s -o /dev/null -w \"%{http_code}\" -k $DNS"
RC=$($CMD)
echo -e "\nRC=$RC"
if [[ "$RC" == "\"200\"" ]]; then
    readAnswer "\"$DNS\" has worked! Congrats!." "" 5 false
else
    readAnswer "\"$DNS\" has failed (RC=$RC). Review the logs and the value file used by helm for some clues" "" 15 false
fi

cd ..
