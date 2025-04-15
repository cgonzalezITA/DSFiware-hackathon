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

# DSFIWAREHOL_FOLDER="DSFiware-hackathon" # TODO DELETE
echo "# Jumping into the hackathon folder ($DSFIWAREHOL_FOLDER)"
cd $DSFIWAREHOL_FOLDER
echo "Now at $(pwd) folder"

# echo "# Removes previously existing apisix namespace"
# echo "# Removes previously existing namespace provider"
# kRemoveRestart ns apisix -y -v       > /dev/null 2>&1 & disown 
# kRemoveRestart ns provider -y -v     > /dev/null 2>&1 & disown 


# echo "# Deployment of the apisix"
# kRemoveRestart ns apisix -y -v       > /dev/null 2>&1
# hFileCommand apisix r -v -y -b       > /dev/null 2>&1 & disown 

# echo "# Deployment of the provider"
# kRemoveRestart ns provider -y -v                > /dev/null 2>&1
# hFileCommand provider/common r -v -y -b         > /dev/null 2>&1 & disown 
# hFileCommand provider/authentication r -v -y -b > /dev/null 2>&1 & disown 
# hFileCommand provider/authorization r -v -y -b  > /dev/null 2>&1 & disown 


# echo "# Waits for the deployment of the different components"
# wait4NamespaceCreated apisix
# wait4PodsDeploymentCompleted apisix       20
# wait4NamespaceCreated provider
# wait4PodsDeploymentCompleted provider     20

# echo "# Registration of the new apisix routes"
# . scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_OIDC_fiwaredsc_vcverifier_local         > /dev/null
# . scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_JWKS_fiwaredsc_vcverifier_local         > /dev/null
# . scripts/manageAPI6Routes.sh insert -r ROUTE_WELLKNOWN_OIDC_Service_fiwaredsc_vcverifier_local > /dev/null


echo -e "\n\n#### Final Verification"
DNS_PROVIDER="fiwaredsc-provider.local"
DNS="https://$DNS_PROVIDER/services/hackathon-service/.well-known/openid-configuration"
CMD="curl -s -o /dev/null -w \"%{http_code}\" -k $DNS"
RC=$($CMD)
echo -e "\nRC=$RC"
if [[ "$RC" == "\"200\"" ]]; then
    echo "\"$DNS\" has worked! Congrats!."
    echo -e "\n**** This quick install ($SCRIPTNAME) has proved:****:
    \t-The provider common components and the ones related with the authentication layer have properly been deployed.
    \t Try running the command=curl -k $DNS or any of the URLs contained in the returned JSON"
else
    readAnswer "\"$DNS\" has failed (RC=$RC). Review the logs and the value file used by helm for some clues" "" 15 false
fi

cd ..
