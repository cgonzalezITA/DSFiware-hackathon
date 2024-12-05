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
DSFIWAREHOL_TAG="phase01.step04"
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

echo "# $DSFIWAREHOL_TAG-Use Admin API to manage routes"
NAMESPACE="apisix"

# DSFIWAREHOL_FOLDER="DSFiware-hackathon1" # TODO DELETE
echo "# Jumping into the hackathon folder ($DSFIWAREHOL_FOLDER)"
cd $DSFIWAREHOL_FOLDER
echo "Now at $(pwd) folder"

echo "# Deploying the apisix helm..."
ARTIFACT_NAME=apisix
hFileCommand $ARTIFACT_NAME -v -y -b restart

readAnswer "On the next screen wait until all the artifacts are properly deployed (1/1)  then press Ctrl+C and the process will continue. Even once available, the initialization of the apisix-data-plane can take several seconds, so be patient" "" 20 false
kGet -w -v -n $NAMESPACE

echo "# Deploy the new routes"
. scripts/manageAPI6Routes.sh insert -r ROUTE_DEMO_JSON
. scripts/manageAPI6Routes.sh insert -r ROUTE_API6DASHBOARD_JSON

DNS_CONSUMER="fiwaredsc-consumer.local"

CMD="curl -s -o /dev/null -w \"%{http_code}\" -k https://$DNS_CONSUMER"
echo "# Running CMD=$CMD"
RC=$($CMD)
echo "RC=$RC"
if [[ "$RC" == "\"200\"" ]]; then
    echo "It has worked! This is the end of $DSFIWAREHOL_TAG. Congrats!"
    echo "Now you can try it running command \"curl -k https://$DNS_CONSUMER\""
    SECRET=$(kSecret-show -n api apisix-dashboard-secrets -f apisix-dashboard-secret -v)
    echo "Better to open it at a browser using \"user;$SECRET\"";
else
    echo "It seems that something has failed (RC=$RC). You can wait some minutes and test again the command \"curl -k https://$DNS_CONSUMER\", else review the logs for some clues"
fi
echo "Script $SCRIPTNAME has finished"
cd ..
