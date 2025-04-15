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
DSFIWAREHOL_TAG="phase03.step02-key"
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

DNS_CONSUMER="fiwaredsc-consumer.local"
echo "# Removes previously existing apisix namespace"
echo "# Removes previously existing namespace consumer"
kRemoveRestart ns apisix -y -v       > /dev/null 2>&1 & disown 
kRemoveRestart ns consumer -y -v     > /dev/null 2>&1 & disown 


echo "# Deployment of the apisix"
kRemoveRestart ns apisix -y -v       > /dev/null 2>&1
hFileCommand apisix r -v -y -b       > /dev/null 2>&1 & disown 

echo "# Deployment of the consumer"
kRemoveRestart ns consumer -y -v     > /dev/null 2>&1
hFileCommand consumer r -v -y -b     > /dev/null 2>&1 & disown 

echo "# Waits for the deployment of the different components"
wait4NamespaceCreated apisix
wait4PodsDeploymentCompleted apisix       20
wait4NamespaceCreated consumer
wait4PodsDeploymentCompleted consumer     20

echo "# Registration of the new apisix routes"
. scripts/manageAPI6Routes.sh insert -r ROUTE_CONSUMER_KEYCLOAK_fiwaredsc_consumer_local > /dev/null

echo -e "\n\n#### Final Verification"
CMD="curl -s -o /dev/null -w \"%{http_code}\" -k https://$DNS_CONSUMER/realms/consumerRealm/account/oid4vci"
RC=$($CMD)
echo -e "\nRC=$RC"
if [[ "$RC" == "\"200\"" ]]; then
    echo -e "\"https://$DNS_CONSUMER\" has worked! Congrats!. Now with the proper configuration you can browse the \"https://$DNS_CONSUMER\" URL"
    echo -e "\n**** This quick install ($SCRIPTNAME) has proved:****:
    \t-Keycloak has been deployed with a configuration able to issue VCredentials"
else
    readAnswer "\"https://$DNS_CONSUMER\" has failed (RC=$RC). Review the logs and the value file used by helm for some clues" "" 15 false
fi

echo "Script $SCRIPTNAME has finished"
cd ..