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
DSFIWAREHOL_TAG="phase05.step04"
STEP_DESCRIPTION="Addition of the authorization checking to the service route"
DSFIWAREHOL_FOLDER="DSFiware-hackathon-$DSFIWAREHOL_TAG"
PUBLIC_IP=$(hostname -I | awk '{print $1}')
DNS_PROVIDER="fiwaredsc-provider.local"
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

echo "# $DSFIWAREHOL_TAG-$STEP_DESCRIPTION"

# DSFIWAREHOL_FOLDER="DSFiware-hackathon" # TODO DELETE
echo "# Jumping into the hackathon folder ($DSFIWAREHOL_FOLDER)"
cd $DSFIWAREHOL_FOLDER
echo "Now at $(pwd) folder"



echo "# Removes previously existing apisix namespace"
kRemoveRestart ns apisix -y -v

echo "# Removes previously existing namespace consumer"
kRemoveRestart ns consumer -y -v

echo "# Removes previously existing namespace provider"
kRemoveRestart ns provider -y -v

echo "# Removes previously existing namespace trust-anchor"
kRemoveRestart ns trust-anchor -y -v


echo "# Deployment of the trust-anchor"
hFileCommand trustAnchor r -v -y -b

echo "# Deployment of the apisix"
hFileCommand apisix r -v -y -b

echo "# Deployment of the provider common"
hFileCommand provider/common r -v -y -b
echo "# Deployment of the provider authentication"
hFileCommand provider/authentication r -v -y -b
echo "# Deployment of the provider authorization"
hFileCommand provider/authorization r -v -y -b

echo "# Registers the fiwaredsc-provider.local at the /etc/hosts file to map the DNS with the IP address"
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
wait4PodsDeploymentCompleted apisix 20
wait4PodsDeploymentCompleted provider 20

echo "# Deployment of the provider service"
hFileCommand provider/service r -v -y -b

echo "# Deployment of the consumer"
hFileCommand consumer r -v -y -b

echo "# Registration of the new apisix routes"
. scripts/manageAPI6Routes.sh insert -r ROUTE_CONSUMER_KEYCLOAK_fiwaredsc_consumer_local
. scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_OIDC_fiwaredsc_vcverifier_local
. scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_JWKS_fiwaredsc_vcverifier_local
. scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_OIDC_Service_fiwaredsc_vcverifier_local
. scripts/manageAPI6Routes.sh insert -r ROUTE_PROVIDER_SERVICE_fiwaredsc_provider_local_2auth
. scripts/manageAPI6Routes.sh insert -r ROUTE_PROVIDER_fiwaredsc_provider_local_dataSpaceConfiguration



wait4PodsDeploymentCompleted service 20 "Note that the init-data pod finishes when it is marked as '0/1 Completed'. Please, be patient"
wait4PodsDeploymentCompleted consumer 20




echo "# Verification"
unset VERIFIABLE_CREDENTIAL
unset DATA_SERVICE_ACCESS_TOKEN
echo "# First of all, a VC is issued to the user with ORDERCONSUMER role"
export VERIFIABLE_CREDENTIAL=$(./scripts/issueVC_operator-credential-orderConsumer.sh -v)
echo "DATA_SERVICE_ACCESS_TOKEN=$VERIFIABLE_CREDENTIAL"
echo "# Now, this VC is used to retrieve the JWT validated to access the service"
export DATA_SERVICE_ACCESS_TOKEN=$(. scripts/generateAccessTokenFromVC.sh $VERIFIABLE_CREDENTIAL -v)
echo "DATA_SERVICE_ACCESS_TOKEN=$DATA_SERVICE_ACCESS_TOKEN"
echo "# Access to the service (with both authentication and authorization enabled):"
export DNS="https://fiwaredsc-provider.local/services/hackathon-service/ngsi-ld/v1/entities?type=Order"
export CMD="curl -s -o /dev/null -w \"%{http_code}\" -k $DNS \
    --header \"Accept: application/json\" \
    --header \"Authorization: Bearer ${DATA_SERVICE_ACCESS_TOKEN}\""
export RC=$(bash -c "$CMD")
echo -e "\nRC=$RC"
if test "$RC" -eq 200; then
    export CMD="curl -s -k $DNS \
    --header \"Accept: application/json\" \
    --header \"Authorization: Bearer ${DATA_SERVICE_ACCESS_TOKEN}\""
    JSON=$(bash -c "$CMD")
    echo "$JSON" | jq empty
    if [ $? -eq 0 ]; then
        readAnswer "\"$CMD\" returns a valid json. It has worked! Congrats!." "" 5 false
    else
        readAnswer "\"$CMD\" has failed. Review the logs and the value file used by helm for some clues" "" 15 false
    fi
    
else
    readAnswer "\"$CMD\" has failed (RC=$RC). Review the logs and the value file used by helm for some clues" "" 15 false
fi

cd ..
