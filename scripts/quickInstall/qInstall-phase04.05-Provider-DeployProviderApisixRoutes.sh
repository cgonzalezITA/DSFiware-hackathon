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
DSFIWAREHOL_TAG="phase04.step05"
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

echo "# $DSFIWAREHOL_TAG-Addition of the service route to the Apisix without security"

# DSFIWAREHOL_FOLDER="DSFiware-hackathon" # TODO DELETE
echo "# Jumping into the hackathon folder ($DSFIWAREHOL_FOLDER)"
cd $DSFIWAREHOL_FOLDER
echo "Now at $(pwd) folder"


echo "# Removes previously existing apisix namespace"
echo "# Removes previously existing namespace service"
kRemoveRestart ns apisix -y -v       > /dev/null 2>&1 & disown 
kRemoveRestart -a ns service  -y -v     > /dev/null 2>&1 & disown 


echo "# Deployment of the apisix"
kRemoveRestart ns apisix -y -v       > /dev/null 2>&1
hFileCommand apisix r -v -y -b       > /dev/null 2>&1 & disown 

echo "# Deployment of the provider's service"
kRemoveRestart -a ns service  -y -v          > /dev/null 2>&1
hFileCommand provider/service r -v -y -b  > /dev/null 2>&1 & disown 


echo "# Waits for the deployment of the different components"
wait4NamespaceCreated apisix
wait4PodsDeploymentCompleted apisix       20
wait4NamespaceCreated service
wait4PodsDeploymentCompleted service      20 "Note that the init-data pod finishes when it is marked as '0/1 Completed'. Please, be patient"

echo "# Registration of the new apisix routes"
. scripts/manageAPI6Routes.sh insert -r ROUTE_PROVIDER_SERVICE_fiwaredsc_provider_local_0auth          > /dev/null


echo -e "\n\n#### Final Verification"
DNS="https://fiwaredsc-provider.local/services/hackathon-service/ngsi-ld/v1/entities?type=Order"
CMD="curl -s -o /dev/null -w \"%{http_code}\" -k $DNS"
RC=$($CMD)
echo -e "\nRC=$RC"
if [[ "$RC" == "\"200\"" ]]; then
    CMD="curl -k $DNS"
    JSON=$($CMD)
    echo "$JSON" | jq empty
    if [ $? -eq 0 ]; then
        echo "\"$CMD\" returns a valid json. It has worked! Congrats!."
        echo -e "\n**** This quick install ($SCRIPTNAME) has proved:****:
        \t-The provider's service components have properly been deployed.
        \tNOTE that neither authentication nor authorization have been enabled at this stage.
        \t Try running the command=curl -k $DNS"
    else
        readAnswer "\"$CMD\" has failed. Review the logs and the value file used by helm for some clues" "" 15 false
    fi
    
else
    readAnswer "\"$DNS\" has failed (RC=$RC). Review the logs and the value file used by helm for some clues" "" 15 false
fi

cd ..
