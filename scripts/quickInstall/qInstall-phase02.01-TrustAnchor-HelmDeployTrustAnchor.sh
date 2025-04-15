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
DSFIWAREHOL_TAG="phase02.step01"
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

echo "# $DSFIWAREHOL_TAG-Deploy the Helm trustAnchor helm chart"
NAMESPACE="trust-anchor"

# DSFIWAREHOL_FOLDER="DSFiware-hackathon1" # TODO DELETE
echo "# Jumping into the hackathon folder ($DSFIWAREHOL_FOLDER)"
cd $DSFIWAREHOL_FOLDER
echo "Now at $(pwd) folder"

echo "# Removes previously existing apisix namespace"
kRemoveRestart ns apisix -y -v       > /dev/null 2>&1 & disown 
echo "# Removes previously existing namespace trust-anchor"
kRemoveRestart ns trust-anchor -y -v > /dev/null 2>&1 & disown 

echo "# Deployment of the apisix"
kRemoveRestart ns apisix -y -v       > /dev/null 2>&1
hFileCommand apisix r -v -y -b       > /dev/null 2>&1 & disown 

echo "# Deployment of the trust-anchor"
kRemoveRestart ns trust-anchor -y -v > /dev/null 2>&1 
hFileCommand trustAnchor r -v -y -b  > /dev/null 2>&1 & disown 

echo "# Waits for the deployment of the different components"
wait4NamespaceCreated apisix
wait4PodsDeploymentCompleted apisix       20
wait4NamespaceCreated trust-anchor
wait4PodsDeploymentCompleted trust-anchor 20

DNS_TRUSTANCHOR="fiwaredsc-trustanchor.local"

echo "# Registration of the new apisix routes"
. scripts/manageAPI6Routes.sh insert -r ROUTE_TIR_JSON  > /dev/null      


echo -e "\n\n#### Final Verification"
CMD="curl -s -o /dev/null -w \"%{http_code}\" -k https://$DNS_TRUSTANCHOR/v4/issuers"
echo "# Running CMD=$CMD"
RC=$($CMD)
echo "RC=$RC"
if [[ "$RC" == "\"200\"" ]]; then
    echo "It has worked! This is the end of $DSFIWAREHOL_TAG. Congrats!"
    echo "Now you can try it running command \"curl -k https://$DNS_TRUSTANCHOR/v4/issuers\""
    echo -e "\n**** This quick install ($SCRIPTNAME) has proved:****:
    \t-The trush-anchor of the data space is deployed and in place to manage registration of new participants
    \t-The trush-anchor can also be used to retrieve already registered identities (https://$DNS_TRUSTANCHOR/v4/issuers)"
   
else
    echo "It seems that something has failed (RC=$RC). You can wait some minutes and test again the command \"curl -k https://$DNS_TRUSTANCHOR/v4/issuers\", else review the logs for some clues"
fi

echo "Script $SCRIPTNAME has finished"
cd ..