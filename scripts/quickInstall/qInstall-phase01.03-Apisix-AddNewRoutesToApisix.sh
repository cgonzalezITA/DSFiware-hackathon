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



echo "# Removes previously existing apisix namespace"
kRemoveRestart ns apisix -y -v       > /dev/null 2>&1 & disown 

echo "# Deployment of the apisix"
kRemoveRestart ns apisix -y -v       > /dev/null 2>&1
hFileCommand apisix r -v -y -b       > /dev/null 2>&1 & disown 

echo "# Waits for the deployment of the different components"
wait4NamespaceCreated apisix
wait4PodsDeploymentCompleted apisix       20


echo -e "\n\n#### Final Verification"

DNS_APISIX="fiwaredsc-api6dashboard.local"
CMD="curl -s -o /dev/null -w \"%{http_code}\" -k https://$DNS_APISIX"
echo "# Running CMD=$CMD"
RC=$($CMD)
echo "RC=$RC"
if [[ "$RC" == "\"200\"" ]]; then
    echo "It has worked! This is the end of $DSFIWAREHOL_TAG. Congrats!"
    echo "Now you can try it running command \"curl -k https://$DNS_APISIX\""
    SECRET=$(kSecret-show -n api apisix-dashboard-secrets -f apisix-dashboard-secret -v)
    echo "Better to open it at a browser using \"user;$SECRET\"";
    
    echo -e "\n**** This quick install ($SCRIPTNAME) has proved:****:
    \t-The apisix dashboard is created and accessible at the https://$DNS_APISIX
    \t-New routes can be defined and managed using this apisix dashboard"

else
    echo "It seems that something has failed (RC=$RC). You can wait some minutes and test again the command \"curl -k https://$DNS_APISIX\", else review the logs for some clues"
fi
echo "Script $SCRIPTNAME has finished"
cd ..
