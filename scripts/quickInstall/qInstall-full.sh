#!/bin/bash
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi
BASEDIR=$(dirname "$SCRIPTNAME")
VERBOSE=true
SUBMODULE=""

. $BASEDIR/_base.sh
SCRIPTNAME=$BASH_SOURCE

unset DID
#---------------------------------------------- main program ------------------------
echo "##############################"
echo "# This script Installs the DSFiware-hackathon Data Space Participants: Consumer, Provider and a Trust anchor"
echo "# It is mandatory to have installed the devopsTools (scripts/installDevopTools.sh)"
echo "# It is mandatory to have installed a minimal Kubernetes cluster  (eg. scripts/installMicrok8s.sh)"
echo "# It is mandatory to register the used DNS (local DNSs)  (sudo scripts/qInstall-dnsRegistration.sh)"


readAnswer "\n*****\n1- Customization of the participants to be installed. Press a key to continue (50sg)" "y" 50
MSG="# Do you want to install/reinstall the trust-anchor helm chart?";
REPLY_TANCHOR=$(readAnswer "$MSG (y*|n)" 'y' 25)
MSG="# Do you want to install/reinstall the consumer helm chart?";
REPLY_CONSUMER=$(readAnswer "$MSG (y*|n)" 'y' 25)
MSG="# Do you want to install/reinstall the apisix helm chart?";
REPLY_API6=$(readAnswer "$MSG (y*|n)" 'y' 25)
MSG="# Do you want to install/reinstall the provider helm charts?";
REPLY_PROVIDER=$(readAnswer "$MSG (y*|n)" 'y' 25)
MSG="# Do you want to install/reinstall the service helm chart?";
REPLY_SERVICE=$(readAnswer "$MSG (y*|n)" 'y' 25)


readAnswer "\n*****\n2- Installation of the participants. Press a key to continue (50sg)" "y" 50
if [ $REPLY_TANCHOR == 'y' ]; then
    echo "# Removes previously existing trust-anchor component"
    kRemoveRestart ns trust-anchor -y -v > /dev/null
    echo "# Deployment of the trust-anchor"
    hFileCommand trustAnchor r -v -y -b 
fi

if [ $REPLY_CONSUMER == 'y' ]; then
    echo "# Removes previously existing consumer component"
    kRemoveRestart ns consumer -y -v > /dev/null
    echo "# Deployment of the consumer"
    hFileCommand consumer r -v -y -b
fi

if [ $REPLY_API6 == 'y' ]; then
    echo "# Removes any previously existing apisix component"
    kRemoveRestart ns apisix -y -v > /dev/null
    echo "# Deployment of the apisix"
    hFileCommand apisix r -v -y -b
fi

if [ $REPLY_PROVIDER == 'y' ]; then
    echo "# Removes any previously existing provider component"
    kRemoveRestart ns provider -y -v > /dev/null

    echo "# Deployment of the provider common"
    hFileCommand provider/common r -v -y -b
    echo "# Deployment of the provider authentication"
    hFileCommand provider/authentication r -v -y -b
    echo "# Deployment of the provider authorization"
    hFileCommand provider/authorization r -v -y -b
fi

if [ $REPLY_SERVICE == 'y' ]; then
    echo "# Removes previously existing namespace service"
    kRemoveRestart ns service -y -v > /dev/null
    echo "# Deployment of the provider service"
    hFileCommand provider/service r -v -y -b    
fi


readAnswer "\n*****\n3- Waiting for the participants to be deployed. Press a key to continue (50sg)" "y" 50
# Waits for the deployment
[ "$REPLY_TANCHOR" == 'y' ] &&  wait4PodsDeploymentCompleted trust-anchor 20
[ "$REPLY_API6" == 'y' ] &&     wait4PodsDeploymentCompleted apisix 20
[ "$REPLY_PROVIDER" == 'y' ] && wait4PodsDeploymentCompleted provider 20
[ "$REPLY_SERVICE" == 'y' ] &&  wait4PodsDeploymentCompleted service 20 "Note that the init-data pod finishes when it is marked as '0/1 Completed'. Please, be patient"
[ "$REPLY_CONSUMER" == 'y' ] && wait4PodsDeploymentCompleted consumer 20


readAnswer "\n*****\n4- Upgrades the components to finalize the configurations. Press a key to continue (50sg)" "y" 50
[ "$REPLY_TANCHOR" == 'y' ] &&  hFileCommand trustAnchor u -y > /dev/null
[ "$REPLY_SERVICE" == 'y' ] &&  hFileCommand service u -y > /dev/null
[ "$REPLY_CONSUMER" == 'y' ] && hFileCommand consumer u -y > /dev/null

readAnswer "\n*****\n5- Registration of the new apisix routes. Press a key to continue (50sg)" "y" 50
. scripts/manageAPI6Routes.sh insert -r ROUTE_CONSUMER_KEYCLOAK_fiwaredsc_consumer_local
. scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_OIDC_fiwaredsc_vcverifier_local
. scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_JWKS_fiwaredsc_vcverifier_local
. scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_OIDC_Service_fiwaredsc_vcverifier_local
. scripts/manageAPI6Routes.sh insert -r ROUTE_PROVIDER_SERVICE_fiwaredsc_provider_local_2auth
. scripts/manageAPI6Routes.sh insert -r ROUTE_PROVIDER_fiwaredsc_provider_local_dataSpaceConfiguration


readAnswer "\n\n*****\n6- final Verification that all the components are working properly. Press a key to continue (50sg)" "y" 50
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