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
echo "# Removes previously existing namespace consumer"
echo "# Removes previously existing namespace trust-anchor"
echo "# Removes previously existing namespace provider"
echo "# Removes previously existing namespace service"
kRemoveRestart ns trust-anchor -y -v > /dev/null 2>&1 & disown 
kRemoveRestart ns apisix -y -v       > /dev/null 2>&1 & disown 
kRemoveRestart ns consumer -y -v     > /dev/null 2>&1 & disown 
kRemoveRestart ns provider -y -v     > /dev/null 2>&1 & disown 
kRemoveRestart -a ns service  -y -v     > /dev/null 2>&1 & disown 


echo "# Deployment of the apisix"
kRemoveRestart ns apisix -y -v       > /dev/null 2>&1
hFileCommand apisix r -v -y -b       > /dev/null 2>&1 & disown 

echo "# Deployment of the consumer"
kRemoveRestart ns consumer -y -v     > /dev/null 2>&1
hFileCommand consumer r -v -y -b     > /dev/null 2>&1 & disown 

echo "# Deployment of the trust-anchor"
kRemoveRestart ns trust-anchor -y -v > /dev/null 2>&1 
hFileCommand trustAnchor r -v -y -b  > /dev/null 2>&1 & disown 

echo "# Deployment of the provider"
kRemoveRestart ns provider -y -v                > /dev/null 2>&1
hFileCommand provider/common r -v -y -b         > /dev/null 2>&1 & disown 
hFileCommand provider/authentication r -v -y -b > /dev/null 2>&1 & disown 
hFileCommand provider/authorization r -v -y -b  > /dev/null 2>&1 & disown 

echo "# Deployment of the provider's service"
kRemoveRestart -a ns service  -y -v          > /dev/null 2>&1
hFileCommand provider/service r -v -y -b  > /dev/null 2>&1 & disown 


echo "# Waits for the deployment of the different components"
wait4NamespaceCreated apisix
wait4PodsDeploymentCompleted apisix       20
wait4NamespaceCreated consumer
wait4PodsDeploymentCompleted consumer     20
wait4NamespaceCreated trust-anchor
wait4PodsDeploymentCompleted trust-anchor 20
wait4NamespaceCreated provider
wait4PodsDeploymentCompleted provider     20
wait4NamespaceCreated service
wait4PodsDeploymentCompleted service      20 "Note that the init-data pod finishes when it is marked as '0/1 Completed'. Please, be patient"

echo "# Refreshes the jobs to register components"
hFileCommand consumer u -y            > /dev/null 2>&1
hFileCommand provider/service u -v -y > /dev/null 2>&1


echo "# Registration of the new apisix routes"
. scripts/manageAPI6Routes.sh insert -r ROUTE_CONSUMER_KEYCLOAK_fiwaredsc_consumer_local                > /dev/null      
. scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_OIDC_fiwaredsc_vcverifier_local                 > /dev/null
. scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_JWKS_fiwaredsc_vcverifier_local                 > /dev/null
. scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_OIDC_Service_fiwaredsc_vcverifier_local         > /dev/null
. scripts/manageAPI6Routes.sh insert -r ROUTE_PROVIDER_SERVICE_fiwaredsc_provider_local_2auth           > /dev/null
. scripts/manageAPI6Routes.sh insert -r ROUTE_PROVIDER_fiwaredsc_provider_local_dataSpaceConfiguration  > /dev/null




echo -e "\n\n#### Final Verification"
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
        echo "\"$CMD\" returns a valid json. It has worked! Congrats!."
        echo -e "\n**** This quick install ($SCRIPTNAME) has proved:****:
        \t-The whole data space infrastructure has been deployed: apisix, trust-anchor, consumer and provider.
        \t\t-The provider's common, authentication, authorization and service components have properly been deployed.
        \t-The consumer has been registered as a trusted participant of the DS and an authorized consumer of the provider's service.
        \t-The service has been registered at the Provider's credential config service.
        \t-Finally, the service is exposed behind the provider's authentication and authorization layer
        \t satisfying the consumer the ODRL policy that authorizes the access to the service.
        \t Try running the command=$CMD"
    else
        readAnswer "\"$CMD\" has failed. Review the logs and the value file used by helm for some clues" "" 15 false
    fi
    
else
    readAnswer "\"$CMD\" has failed (RC=$RC). Review the logs and the value file used by helm for some clues" "" 15 false
fi

cd ..
